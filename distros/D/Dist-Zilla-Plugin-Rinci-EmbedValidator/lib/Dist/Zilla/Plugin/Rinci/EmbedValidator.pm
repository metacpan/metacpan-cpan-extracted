package Dist::Zilla::Plugin::Rinci::EmbedValidator;

our $DATE = '2019-07-04'; # DATE
our $VERSION = '0.250'; # VERSION

use 5.010001;
use strict;
use warnings;

use Data::Dmp;
use Data::Sah;
use Perinci::Sub::Normalize qw(normalize_function_metadata);
use PMVersions::Util qw(version_from_pmversions);

my $sah = Data::Sah->new();
my $plc = $sah->get_compiler("perl");
$plc->indent_character('');

use Moose;
use experimental 'smartmatch';
use namespace::autoclean;

with (
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [':InstallModules'],
    },
);

sub _add_prereq {
    my ($self, $mod, $ver) = @_;
    return if defined($self->{_added_prereqs}{$mod}) &&
        $self->{_added_prereqs}{$mod} >= $ver;
    $self->log("Adding prereq: $mod => $ver");
    $self->zilla->register_prereqs({phase=>'runtime'}, $mod, $ver);
    $self->{_added_prereqs}{$mod} = $ver;
}

sub __squish_code {
    my $code = shift;
    for ($code) {
        s/^\s*#.+//mg; # comment line
        s/^\s+//mg;    # indentation
        s/\n+/ /g;     # newline
    }
    $code;
}

sub munge_files {
    my $self = shift;

    $self->munge_file($_) for @{ $self->found_files };
    return;
}

sub munge_file {
    my ($self, $file) = @_;

    my $fname = $file->name;

    unless ($file->isa("Dist::Zilla::File::OnDisk")) {
        $self->log_debug(["skipping %s: not an ondisk file, currently only ondisk files are processed", $fname]);
        return;
    }

    $self->log_debug("Processing file $fname ...");

    unless ($fname =~ m!lib/(.+\.pm)$!) {
        #$self->log_debug("Skipping: '$fname' not a module");
        return;
    }
    my $reqname = $1;

    # i do it this way (unshift @INC, "lib" + require "Foo/Bar.pm" instead of
    # unshift @INC, "." + require "lib/Foo/Bar.pm") in my all other Dist::Zilla
    # and Pod::Weaver plugin, so they can work together (require "Foo/Bar.pm"
    # and require "lib/Foo/Bar.pm" would cause Perl to load the same file twice
    # and generate redefine warnings).

    local @INC = ("lib", @INC);

    eval { require $reqname };
    if ($@) {
        $self->log_fatal("$fname: has compile errors: $@");
    }

    my @content = split /^/, $file->content;
    my $munged;
    my $in_pod;
    my ($pkg_name, $sub_name, $metas, $meta, $arg, $var);
    my $sub_has_vargs; # VALIDATE_ARGS has been declared for current sub
    my %vargs; # list of validated args for current sub, val 2=skipped
    my %vsubs; # list of subs
    my %vars;    # list of variables that the generated validator needs
    my @modules; # list of modules (records) that the generated validator needs

    my $i = 0; # line number

    my $check_prev_sub = sub {
        return unless $sub_name;
        return unless $meta;
        my %unvalidated;
        for (keys %{ $meta->{args} }) {
            next unless $meta->{args}{$_}{schema};
            $unvalidated{$_}++ unless $vargs{$_};
        }
        if (keys %unvalidated) {
            $self->log("NOTICE: $fname: Some argument(s) not validated ".
                           "for sub $sub_name: ".
                               join(", ", sort keys %unvalidated));
        } elsif (!$meta->{"x.perinci.sub.wrapper.disable_validate_args"}) {
            $self->log(
                "NOTICE: $fname: You might want to set ".
                    "x.perinci.sub.wrapper.disable_validate_args => 1 in metadata ".
                        "for sub $sub_name");
        }
    };

    my $gen_err = sub {
        my ($status, $msg, $cond) = @_;
        if ($meta->{result_naked}) {
            return qq[if ($cond) { die "$sub_name(): " . $msg } ];
        } else {
            return qq|if ($cond) { return [$status, $msg] } |;
        }
    };
    my $gen_merr = sub {
        my ($cond, $arg) = @_;
        $gen_err->(400, qq["Missing argument: $arg"], $cond);
    };
    my $gen_verr = sub {
        my ($cond, $arg) = @_;
        $gen_err->(400, qq["Invalid argument value for $arg: \$arg_err"],
                   $cond);
    };

    my $gen_arg = sub {
        my $meta = $metas->{$sub_name};
        my $as   = $meta->{args}{$arg} or
            $self->log_fatal(["No spec for argument '%s' in the Rinci metadata", $arg]);
        my $dn = $arg; $dn =~ s/\W+/_/g;
        my $has_default_prop = exists($as->{default});
        my $cd = $plc->compile(
            schema      => $meta->{args}{$arg}{schema},
            err_term    => '$arg_err',
            data_name   => $dn,
            data_term   => $var,
            return_type => 'str',
            comment     => 0,
        );
        die "Incompatible Data::Sah version (cd v=$cd->{v}, expected 2)" unless $cd->{v} == 2;
        my @code;
        if ($has_default_prop) {
            push @code, "$var //= ", dmp($as->{default}), ";";
        }
        for (sort keys %{$cd->{vars}}) {
            push @code, "my \$$_ = ".$plc->literal($cd->{vars}{$_})."; "
                unless exists($vars{$_});
            $vars{$_}++;
        }
        push @code, 'my $arg_err; ' unless keys %vargs;

        # limit the effect of pragmas that might be introduced by the generated
        # code
        push @code, "{ ";

        for my $mod_rec (@{$cd->{modules}}) {
            next unless $mod_rec->{phase} eq 'runtime';
            $self->_add_prereq($mod_rec->{name} => $mod_rec->{version} // version_from_pmversions($mod_rec->{name}) // 0);
            push @code, $plc->stmt_require_module($mod_rec) unless
                grep { $_->{name} eq $mod_rec->{name} && !$mod_rec->{use_statement} } @modules;
            push @modules, $mod_rec;
        }
        push @code, __squish_code($cd->{result}), "; ";
        push @code, $gen_verr->('$arg_err', $arg);
        $vargs{$arg} = 1;

        # enclose the pragma-limiter block
        push @code, "} ";

        join "", @code;
    };

    my $gen_args = sub {
        my @code;
        my $needs_to_close_pragma_limiting_block;
        for my $arg (sort keys %{ $meta->{args} }) {
            my $as = $meta->{args}{$arg};
            my $has_default_prop = exists($as->{default});
            my $sn = $meta->{args}{$arg}{schema}; # already normalized by normalize_function_metadata()
            my $kvar; # var to access a hash key
            $kvar = $var; $kvar =~ s/.//;
            $kvar = join(
                "",
                "\$$kvar",
                (($meta->{args_as} // "hash") eq "hashref" ? "->" : ""),
                "{'$arg'}",
            );
            if ($has_default_prop) {
                push @code, "$kvar //= ", dmp($as->{default}), ";";
            }
            if ($sn) {
                my $has_sch_default = exists($sn->[1]{default});
                my $dn = $arg; $dn =~ s/\W+/_/g;
                my $cd = $plc->compile(
                    schema      => $sn,
                    schema_is_normalized => 1,
                    err_term    => '$arg_err',
                    data_name   => $dn,
                    data_term   => $kvar,
                    return_type => 'str',
                    comment     => 0,
                );
                die "Incompatible Data::Sah version (cd v=$cd->{v}, expected 2)" unless $cd->{v} == 2;
                for (sort keys %{$cd->{vars}}) {
                    push @code, "my \$$_ = ".$plc->literal($cd->{vars}{$_})."; "
                        unless exists($vars{$_});
                    $vars{$_}++;
                }
                push @code, 'my $arg_err; ' unless keys %vargs;
                $vargs{$arg} = 1;

                # limit the effect of pragmas that might be introduced by the
                # generated code
                unless ($needs_to_close_pragma_limiting_block) {
                    push @code, "{ ";
                    $needs_to_close_pragma_limiting_block++;
                }

                for my $mod_rec (@{$cd->{modules}}) {
                    next unless $mod_rec->{phase} eq 'runtime';
                    $self->_add_prereq($mod_rec->{name} => $mod_rec->{version} // version_from_pmversions($mod_rec->{name}) // 0);
                    push @code, $plc->stmt_require_module($mod_rec) unless
                        grep { $_->{name} eq $mod_rec->{name} && !$mod_rec->{use_statement} } @modules;
                    push @modules, $mod_rec;
                }
                push @code, "if (exists($kvar)) { ";
                push @code,     __squish_code($cd->{result}), "; ";
                push @code,     $gen_verr->('$arg_err', $arg);
                push @code, "}";
                if ($has_sch_default) {
                    push @code, " else { ";
                    push @code,     "$kvar = ", dmp($sn->[1]{default}), ";";
                    push @code, "}";
                }
            }

            if ($as->{req}) {
                push @code, $gen_merr->("!exists($kvar)", $arg);
            }
        }

        push @code, "} " if $needs_to_close_pragma_limiting_block;

        join "", @code;
    };

    for (@content) {
        $i++;
        if (/^=cut\b/x) {
            $in_pod = 0;
            next;
        }
        next if $in_pod;
        if (/^=\w+/x) {
            $in_pod++;
            next;
        }
        if (/^\s*package \s+ (\w+(?:::\w+)*) \s*;/x) {
            no strict 'refs';
            $pkg_name = $1;
            $self->log_debug("Found package declaration $pkg_name");
            $metas = \%{"$pkg_name\::SPEC"};
            for (keys %$metas) {
                $metas->{$_} = normalize_function_metadata($metas->{$_});
            }
            next;
        }
        if (/^\s*sub \s+ (\w+)/x) {
            $self->log_debug("Found sub declaration $1");
            unless ($pkg_name) {
                $self->log_fatal(
                    "$fname:$i: module does not have package definition");
            }
            $check_prev_sub->();
            $sub_name      = $1;
            $sub_has_vargs = 0;
            %vargs         = ();
            @modules       = ();
            %vars          = ();
            $meta          = $metas->{$sub_name};
            next;
        }
        if (/^\s*?
             (?<code>\s* my \s+ (?<sigil>[\$@%]) (?<var>\w+) \b .+)?
             (?<tag>\#\s*(?<no>NO_)?VALIDATE_ARG(?<s> S)?
                 (?: \s+ (?<var2>\w+))? \s*$)/x) {
            my %m = %+;
            $self->log_debug("Found line with tag $_, m=" .
                                 join(', ', map {"$_=>$m{$_}"} keys %m));
            next if !$m{no} && !$m{code};
            $arg = $m{var2} // $m{var};
            if ($m{no}) {
                if ($m{s}) {
                    %vargs = map {$_=>2} keys %{$meta->{args} // {}};
                } else {
                    $vargs{$arg} = 2;
                }
                next;
            }
            $var = $m{sigil} . $m{var};
            unless ($sub_name) {
                $self->log_fatal("$fname:$i: # VALIDATE_ARG$m{s} outside sub");
            }
            unless ($meta) {
                $self->log_fatal(
                    "$fname:$i: sub $sub_name does not have metadata");
            }
            if (($meta->{v} // 1.0) != 1.1) {
                $self->log_fatal(
                    "$fname:$i: metadata for sub $sub_name is not v1.1 ".
                        "(currently only v1.1 is supported)");
            }
            if ($m{s} && ($meta->{args_as} // "hash") !~ /^hash(ref)?$/) {
                $self->log_fatal(
                    "$fname:$i: metadata for sub $sub_name: ".
                        "args_as=$meta->{args_as} (sorry, currently only ".
                            "args_as=hash/hashref supported for validating all args at once (# VALIDATE_ARGS), try validating one arg at a time (# VALIDATE_ARG))");
            }
            unless ($meta->{args}) {
                $self->log_fatal(
                    "$fname:$i: # metadata for sub $sub_name: ".
                        "no args property defined");
            }
            if ($m{s} && $sub_has_vargs) {
                $self->log_fatal(
                    "$fname:$i: multiple # VALIDATE_ARGS for sub $sub_name");
            }
            if (!$m{s}) {
                unless ($meta->{args}{$arg} && $meta->{args}{$arg}{schema}) {
                    $self->log_fatal(
                        "$fname:$i: metadata for sub $sub_name: ".
                            "no schema for argument $arg");
                }
            }
            if ($m{s} && $m{sigil} !~ /[\$%]/) {
                $self->log_fatal(
                    "$fname:$i: invalid variable $var ".
                        "for # VALIDATE_ARGS, must be hash/hashref");
            }
            if (!$m{s} && $m{sigil} ne '$') {
                $self->log_fatal(
                    "$fname:$i: invalid variable $var ".
                        "for # VALIDATE_ARG, must be scalar");
            }

            $munged++;
            if ($m{s}) {
                $_ = $m{code} . $gen_args->() . $m{tag};
            } else {
                $_ = $m{code} . $gen_arg->()  . $m{tag};
            }
        }
    }
    $check_prev_sub->();

    if ($munged) {
        $self->log("Adding argument validation code for $fname");
        $file->content(join "", @content);
    }

    return;
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Embed schema validator code in built code

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Rinci::EmbedValidator - Embed schema validator code in built code

=head1 VERSION

This document describes version 0.250 of Dist::Zilla::Plugin::Rinci::EmbedValidator (from Perl distribution Dist-Zilla-Plugin-Rinci-EmbedValidator), released on 2019-07-04.

=head1 SYNOPSIS

In dist.ini:

 [Rinci::EmbedValidator]

In your module:

 $SPEC{foo} = {
     args => {
         arg1 => { schema => ['int*', default=>3] },
         arg2 => { },
     },
 };
 sub foo {
     my %args = @_;

     my $arg1 = $args{arg1}; # VALIDATE_ARG
     ...
 }

The built version will become something like:

 $SPEC{foo} = {
     args => {
         arg1 => { schema => ['int*', default=>3] },
         arg2 => { },
     },
 };
 sub foo {
     my %args = @_;

     my $arg1 = $args{arg1}; { require Scalar::Util::Numeric; my $arg_err; (($arg1 //= 3), 1) && ((defined($arg1)) ? 1 : (($err_arg1 = 'TMPERRMSG: required data not specified'),0)) && ((Scalar::Util::Numeric::isint($arg1)) ? 1 : (($err_arg1 = 'TMPERRMSG: type check failed'),0)); return [400, "Invalid value for arg1: $err_arg1"] if $arg1; } # VALIDATE_ARG
     ...
 }

You can also validate all arguments:

 sub foo {
     my %args = @_; # VALIDATE_ARGS

     ...
 }

=head1 DESCRIPTION

This plugin generates schema validation code then embeds the code into your
module source code, at location marked with C<# VALIDATE_ARG> or C<#
VALIDATE_ARGS>. The validation code is generated by L<Data::Sah> from Sah
schemas specified in C<args> property in C<Rinci> function metadata in the
module.

TODO: Embed result/return validation code.

=head2 USAGE

To validate a single argument, in your module:

 sub foo {
     my %args = @_;
     my $arg1 = $args{arg1}; # VALIDATE_ARG

The significant part that is interpreted by this module is C<my $arg1>. Argument
name is taken from the lexical variable's name (in this case, C<arg1>). Argument
must be defined in the C<args> property of the function metadata. If argument
name is different from lexical variable name, then you need to say:

 my $f = $args->{frobnicate}; # VALIDATE_ARG frobnicate

To validate all arguments of the subroutine, you can say:

 sub foo {
     my %args = @_; # VALIDATE_ARGS

There should only be one VALIDATE_ARGS per subroutine.

If you use this plugin, and you plan to wrap your functions too using
L<Perinci::Sub::Wrapper> (or through L<Perinci::Access>, L<Perinci::CmdLine>,
etc), you might also want to put C<< x.perinci.sub.wrapper.disable_validate_args
=> 1 >> attribute into your function metadata, to instruct
L<Perinci::Sub::Wrapper> to skip generating argument validation code when your
function is wrapped, as argument validation is already done by the generated
code.

If there is an unvalidated argument, this plugin will emit a warning notice. To
skip validating an argument (silence the warning), you can use:

 sub foo {
     my %args = @_;
     my $arg1 = $args{arg1}; # NO_VALIDATE_ARG

or:

 sub foo {
     # NO_VALIDATE_ARGS

=for Pod::Coverage ^(munge_file|munge_files)$

=head1 FAQ

=head2 Rationale for this plugin?

This plugin is an alternative to L<Perinci::Sub::Wrapper> and
L<Dist::Zilla::Plugin::Rinci::Wrap>, at least when it comes to validating
arguments. Perinci::Sub::Wrapper can also generate argument validation code
(among other things), but it is done during runtime and can add to startup
overhead (compiling complex schemas for several subroutines can take up to 100ms
or more, on my laptop). Using this plugin, argument validation code is generated
during building of your distribution.

Using this plugin also makes sure that argument is validated whether your
subroutine is wrapped or not. Using this plugin also avoids wrapping and adding
nest level, if that is not to your liking.

Instead of using this plugin, you can use wrapping either by using
L<Perinci::Exporter> or by calling Perinci::Sub::Wrapper's C<wrap_sub> directly.

Another alternative to using this plugin is
L<Dist::Zilla::Plugin::Rinci::GenSchemaV>. Instead of embedding the validator
code directly in the same file, this plugin creates
C<Sah::SchemaV::YOUR_MODULE_NAME> modules and put the generated validator code
there. L<Perinci::CmdLine::Lite> can use this validator code instead of
generating the validator code dynamically with L<Data::Sah>, saving some startup
time.

=head2 But why use Rinci metadata or Sah schema?

In short, adding L<Rinci> metadata to your subroutines allows various tools to
do useful stuffs, relieving you from doing those stuffs manually. Using L<Sah>
schema allows you to write validation code succintly, and gives you the ability
to automatically generate Perl/JavaScript/error messages from the schema.

See their respective documentation for more details.

=head2 But the generated code looks ugly!

Admittedly, yes. Validation source code is formatted as a single long line to
avoid modifying line numbers, which is desirable when debugging your modules. An
option to not compress everything as a single line might be added in the future.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-Rinci-EmbedValidator>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-Rinci-EmbedValidator>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Rinci-EmbedValidator>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Alternative approach to generating validator code:
L<Dist::Zilla::Plugin::Rinci::Wrap>, L<Dist::Zilla::Plugin::Rinci::GenSchemaV>

L<Data::Sah::Manual::ParamsValidating>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
