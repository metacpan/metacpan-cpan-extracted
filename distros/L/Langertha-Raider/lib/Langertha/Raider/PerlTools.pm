package Langertha::Raider::PerlTools;
our $VERSION = '0.503';
# ABSTRACT: MCP::Server factory with Perl evaluation, syntax check, and module install

use strict;
use warnings;
use Path::Tiny;
use File::Which ();
use MCP::Server;
use IPC::Run qw( run start timeout );
use JSON::MaybeXS ();
use Langertha::Raider::Binary qw( packed_binary );
use Langertha::Raider::Home;
use Langertha::Raider::SessionStore;

use Exporter 'import';
our @EXPORT_OK = qw( build_perl_tools_server );


# The perl the tools run, or undef when there is none. A raider script
# runs them with its own perl. The standalone binary (PAR::Packer) has
# none: $^X is not a usable interpreter there, so it takes the perl on PATH.
sub _tool_perl {
  return $^X unless packed_binary();
  return scalar File::Which::which('perl');
}

# The $] of $perl, for the lib's perl-version marker: the perl that uses
# the lib, which in the standalone binary is not the one running this
# code. undef when that perl does not answer.
sub _tool_perl_version {
  my ( $perl ) = @_;
  return $] unless packed_binary();
  my ( $out, $err ) = ( '', '' );
  return unless eval { run([ $perl, '-e', 'print $]' ], \'', \$out, \$err, timeout(30)) };
  return $1 if $out =~ /\A(\d+\.\d+)\z/;
  return;
}

sub _no_perl_message {
  my ( $tool_name, $what ) = @_;
  return $tool_name.': no perl to run '.( $what // 'the code' ).': this raider is the standalone '
       . 'binary, which has no perl interpreter of its own, and there is no perl '
       . 'on PATH. Install perl or put it on PATH.';
}

sub build_perl_tools_server {
  my %args = @_;
  my $root       = path($args{root} // '.')->absolute;
  my $lib_target_override = $args{lib_target};
  my $install_timeout     = $args{install_timeout} // 300;

  my $resolve_lib_target = sub {
    return path($lib_target_override)->absolute($root)->stringify if defined $lib_target_override;
    return Langertha::Raider::Home->project_base($root)->child('lib')->stringify;
  };

  my $perl5lib_for = sub {
    my ($target) = @_;
    my $base = path($target)->child('lib', 'perl5')->stringify;
    return join ':', grep { defined && length } ($base, $ENV{PERL5LIB});
  };

  my $in_root = sub {
    my ($p) = @_;
    return 0 if grep { $_ eq '..' } split m{/}, $p;
    return $root->subsumes(path($p)->absolute($root));
  };

  my $chdir_root = sub { chdir $root or die "chdir $root: $!\n" };

  # IPC::Run leaves the child running when finish dies on a timeout:
  # kill it (TERM, then KILL after the grace period) before rethrowing.
  my $finish = sub {
    my ($h) = @_;
    unless (eval { $h->finish; 1 }) {
      my $e = $@;
      eval { $h->kill_kill(grace => 2) };
      die $e;
    }
    my $fr = $h->full_result;
    return defined($fr) ? ($fr >> 8) : -1;
  };

  # Runs cpanm; a timeout or start failure comes back as the second
  # value ('timeout' or the message) instead of as an exception.
  my $run_cpanm = sub {
    my ($cmd, $out, $err) = @_;
    my $empty = '';
    my $rc;
    return ($rc) if eval {
      $rc = $finish->(start $cmd, \$empty, $out, $err, timeout($install_timeout));
      1;
    };
    my $failure = $@ =~ /^IPC::Run: timeout on timer/ ? 'timeout' : $@;
    chomp $failure;
    return (-1, $failure);
  };

  # $perl is the perl that will use the lib; the marker records its version.
  my $ensure_lib_init = sub {
    my ($target, $perl) = @_;
    my $dir = path($target);
    return if -d $dir && -f $dir->child('cpanfile');

    # A target in the project's .raider/ comes with its .gitignore.
    my $store = Langertha::Raider::SessionStore->new(root => $root->stringify);
    $store->prepare_base if $store->base->subsumes($dir->absolute($root));
    $dir->mkpath;
    my $perl_version = _tool_perl_version($perl);
    $dir->child('perl-version')->spew_utf8($perl_version."\n") if defined $perl_version;
    $dir->child('cpanfile')->spew_utf8(";\n");
    return;
  };

  my $append_to_cpanfile = sub {
    my ($target, $module) = @_;
    my $cpanfile = path($target)->child('cpanfile');
    my $content = $cpanfile->slurp_utf8;
    return if $content =~ /\b\Q$module\E\b/m;
    $cpanfile->append_utf8("requires '$module';\n");
    return;
  };

  # --- Tool: perl_eval ---

  my $server = MCP::Server->new(name => 'raider-perl', version => '1.0');

  $server->tool(
    name        => 'perl_eval',
    description => 'Evaluate a snippet of Perl code and return stdout, stderr, exit code, and return value. Runs in the working root with the private lib on PERL5LIB. No persistent session — each call starts fresh. On missing-module error: auto-installs once and retries.',
    input_schema => {
      type       => 'object',
      properties => {
        code    => { type => 'string', description => 'Perl code to eval (as one-liner or block)' },
        stdin   => { type => 'string', description => 'String to feed to STDIN (optional)' },
        timeout => { type => 'integer', description => 'Max seconds before kill (default: 60)', default => 60 },
      },
      required => ['code'],
    },
    code => sub {
      my ($tool, $in) = @_;
      my $code   = $in->{code}    // '';
      my $stdin  = $in->{stdin}  // '';
      my $to_sec = $in->{timeout} // 60;

      my $perl = _tool_perl();
      return $tool->text_result(_no_perl_message('perl_eval'), 1) unless defined $perl;

      my ($out, $err, $auto_installed, $failure);

      my $do_run = sub {
        my @cmd = ($perl, '-e', $code);
        my $target = $resolve_lib_target->();
        local $ENV{PERL5LIB} = $perl5lib_for->($target);
        my $h = start \@cmd, \$stdin, \$out, \$err, init => $chdir_root, timeout($to_sec);
        return $finish->($h);
      };

      # Both the first run and the retry after auto-install report a
      # timeout or start failure as error, never as an exception.
      my $guarded_run = sub {
        my $rc;
        return $rc if eval { $rc = $do_run->(); 1 };
        $failure = $@ =~ /^IPC::Run: timeout on timer/ ? 'timeout' : $@;
        chomp $failure;
        $err //= '';
        chomp $err;
        return -1;
      };

      my $rc = $guarded_run->();

      # Auto-recover: check for "Can't locate X/Y.pm" once
      my @missing;
      if ($err && $err =~ /^Can't locate (\S+\.pm)/m) {
        my $mod = $1;
        $mod =~ s{/}{::}g;
        $mod =~ s{\.pm$}{};
        push @missing, $mod;
      }

      if (@missing && !$auto_installed && !$failure) {
        my ($i_out, $i_err);
        my $target = $resolve_lib_target->();
        $ensure_lib_init->($target, $perl);
        my ($i_rc, $i_failure) = $run_cpanm->(['cpanm', '--local-lib', $target, @missing], \$i_out, \$i_err);

        if ($i_rc == 0) {
          $auto_installed = \@missing;
          $append_to_cpanfile->($target, $_) for @missing;
          $rc = $guarded_run->();
        }
        else {
          $err .= "\n[auto-install failed for @missing: ".($i_failure // $i_err // '')."]";
        }
      }

      my $return_value;
      if (defined $out && length $out) {
        chomp(my @lines = split /\n/, $out);
        $return_value = $lines[-1] if @lines;
      }

      my %result = (
        stdout       => $out // '',
        stderr       => $err // '',
        return_value => $return_value,
        exit_code    => $rc // 0,
      );
      $result{auto_installed} = $auto_installed if $auto_installed;
      $result{error} = $failure if $failure;

      return $tool->structured_result(\%result);
    },
  );

  # --- Tool: perl_check ---

  $server->tool(
    name        => 'perl_check',
    description => 'Compile-check Perl code with "perl -c" in the working root, with the private lib on PERL5LIB. Not a sandbox: BEGIN blocks and use statements DO run during compilation.',
    input_schema => {
      type       => 'object',
      properties => {
        code => { type => 'string', description => 'Perl code to syntax-check' },
      },
      required => ['code'],
    },
    code => sub {
      my ($tool, $in) = @_;
      my $code = $in->{code} // '';

      my $perl = _tool_perl();
      return $tool->text_result(_no_perl_message('perl_check'), 1) unless defined $perl;

      my ($out, $err);
      local $ENV{PERL5LIB} = $perl5lib_for->($resolve_lib_target->());
      my $h = start [$perl, '-c', '-'], \$code, \$out, \$err, init => $chdir_root, timeout(30);
      my $rc = $finish->($h);

      my $valid = ($rc == 0) ? JSON::MaybeXS::true() : JSON::MaybeXS::false();
      my $syntax_error;
      if ($rc != 0 && $err) {
        $syntax_error = $err;
        chomp $syntax_error;
      }

      return $tool->structured_result({
        valid        => $valid,
        syntax_error => $syntax_error // undef,
      });
    },
  );

  # --- Tool: perl_cpanm ---

  $server->tool(
    name        => 'perl_cpanm',
    description => 'Install a CPAN module into a private local::lib. Target: options.target (must lie inside the working root) > configured lib target > .raider/lib in the working root. Creates the target directory (with cpanfile + perl-version marker) on first install.',
    input_schema => {
      type       => 'object',
      properties => {
        module  => { type => 'string', description => 'Module name (or distribution) to install' },
        options => {
          type       => 'object',
          description => 'Installation options',
          properties => {
            test   => { type => 'boolean', description => 'Run tests before install (default: false)' },
            force  => { type => 'boolean', description => 'Force install (ignore errors)' },
            from   => { type => 'string',  description => 'CPAN mirror URL or path' },
            target => { type => 'string',  description => 'Override lib target directory (inside the working root; relative paths resolve against it)' },
          },
        },
      },
      required => ['module'],
    },
    code => sub {
      my ($tool, $in) = @_;
      my $module = $in->{module}  // '';
      my $opts   = $in->{options} // {};
      my $explicit_target = $opts->{target} // undef;

      if (defined $explicit_target) {
        return $tool->text_result('perl_cpanm: target '.$explicit_target.' is outside the working root '.$root, 1)
          unless $in_root->($explicit_target);
      }

      # cpanm is a perl script, and the modules are for the tool perl.
      my $perl = _tool_perl();
      return $tool->text_result(_no_perl_message('perl_cpanm', 'cpanm'), 1) unless defined $perl;

      my $target_dir = defined $explicit_target
        ? path($explicit_target)->absolute($root)->stringify
        : $resolve_lib_target->();

      $ensure_lib_init->($target_dir, $perl);

      my @cmd = ('cpanm', '--local-lib', $target_dir);
      push @cmd, '--test'    if $opts->{test};
      push @cmd, '--force'   if $opts->{force};
      push @cmd, '--from', $opts->{from} if $opts->{from};
      push @cmd, $module;

      my ($out, $err);
      my ($rc, $failure) = $run_cpanm->(\@cmd, \$out, \$err);

      $append_to_cpanfile->($target_dir, $module) if $rc == 0;

      my $installed = ($rc == 0) ? JSON::MaybeXS::true() : JSON::MaybeXS::false();

      return $tool->structured_result({
        installed => $installed,
        target    => $target_dir,
        version   => undef,
        stdout    => $out // '',
        stderr    => $err // '',
        $failure ? ( error => $failure ) : (),
      });
    },
  );

  return $server;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::PerlTools - MCP::Server factory with Perl evaluation, syntax check, and module install

=head1 VERSION

version 0.503

=head1 DESCRIPTION

The Perl-native tools of L<raider>: an L<MCP::Server> with
C<perl_eval(code, [stdin], [timeout])>, C<perl_check(code)> and
C<perl_cpanm(module, [options])>, all run as subprocesses in the working
root, with a private local::lib on C<PERL5LIB>. C<perl_eval> and
C<perl_check> run the perl that runs raider; the standalone binary has no
usable perl of its own, so there they run the C<perl> on C<PATH>. Without
one all three tools are a tool error there, and nothing runs.

=head2 build_perl_tools_server

    my $server = Langertha::Raider::PerlTools::build_perl_tools_server(
        root       => '/some/dir',  # working root (default: the current directory)
        lib_target => '.raider/lib',  # optional override
        install_timeout => 300,       # seconds per cpanm run (default 300)
    );

Returns an L<MCP::Server> instance with the tools C<perl_eval>, C<perl_check>,
and C<perl_cpanm> registered. A lib target inside the project's F<.raider/>
(the default, F<.raider/lib>) is created through
L<Langertha::Raider::SessionStore/prepare_base>, which writes
F<.raider/.gitignore> when there is none.

=head1 TOOLS

=head2 perl_eval

Evaluate Perl code with the running perl (C<$^X>) in the working root,
with the private lib on C<PERL5LIB>, killed after C<timeout> seconds
(default 60). Returns stdout, stderr, exit_code,
return_value, and (optionally) auto_installed. C<error> is C<timeout> when
the time limit hit, otherwise the message of whatever else failed.

On "Can't locate X/Y.pm" in stderr, auto-installs the module once then
retries the eval. If retry still fails, returns the error. A failed or
timed-out install is noted in C<stderr>.

In the standalone binary, which has no usable perl of its own, the code
runs with the C<perl> on C<PATH>. Without one the call is a tool error
that says so, and nothing runs.

=head2 perl_check

Compile-check Perl code via C<perl -c> in the working root, with the
private lib on C<PERL5LIB>. This is not a sandbox: C<BEGIN> blocks and
C<use> statements run during compilation, for at most 30 seconds. The perl
is the one L</perl_eval> uses.
Returns C<valid> (bool) and
C<syntax_error> (string or null).

=head2 perl_cpanm

Install a CPAN module into a private local::lib. An explicit
C<options.target> must lie inside the working root (relative paths resolve
against it); anything else is rejected. Creates the target
directory (with cpanfile + perl-version marker) on first install. The
marker holds C<$]> of the perl the lib is for, the one L</perl_eval> uses;
in the standalone binary that perl is asked for it. The
cpanfile is updated idempotently (no duplicate entries).
In the standalone binary without a C<perl> on C<PATH> the call is a tool
error, as for L</perl_eval>, and cpanm does not run.
C<error> is C<timeout> when cpanm hit the C<install_timeout> limit,
otherwise the message of whatever else kept it from running.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-raider/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
