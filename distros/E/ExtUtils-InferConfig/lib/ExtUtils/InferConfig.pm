package ExtUtils::InferConfig;

use strict;
use Config;
use Carp qw/croak/;
use IPC::Cmd qw//;

use vars qw/$VERSION/;
BEGIN {
    $VERSION = '1.04';
}

#use constant ISWIN32 => ($^O =~ /win32/i ? 1 : 0);

=head1 NAME

ExtUtils::InferConfig - Infer Perl Configuration for non-running interpreters

=head1 SYNOPSIS

  use ExtUtils::InferConfig;
  my $eic = ExtUtils::InferConfig->new(
    perl => '/path/to/a/perl'
  );
  
  # Get that interpreters %Config as hash ref
  my $Config = $eic->get_config;
  
  # Get that interpreters @INC as array ref
  my $INC = $eic->get_inc;

=head1 DESCRIPTION

This module can determine the configuration and C<@INC> of a perl
interpreter given its path and that it is runnable by the current
user.

It runs the interpreter with a one-liner and grabs the C<%Config>
hash via STDOUT capturing. Getting the module load paths, C<@INC>,
works the same way for C<@INC> entries that are plain paths.

=head1 METHODS

=head2 new

Requires one named parameter: C<perl>, the path to the perl
interpreter to query for information.

Optional parameter: C<debug =E<gt> 1> enables the debugging mode.

=cut

sub new {
    my $class = shift;
    $class = ref($class) || $class;

    my %args = @_;


    my $self = {
        perl => undef,
        config => undef,
        inc => undef,
        ($args{debug} ? (debug => 1) : ()),
    };
    bless $self => $class;

    # get interpreter, check that we have access
    my $perl = $args{perl} || $^X;
    $perl = $self->_perl_to_file($perl);

    if (not defined $perl) {
        croak(
            "Invalid perl interpreter specified. "
            ."It was either not found or it is not executable."
        );
    }

    warn "Using perl '$perl'" if $self->{debug};

    $self->{perl} = $perl;

    return $self;
}

sub _perl_to_file {
    # see perldoc perlvar about this. Look for $^X
    my $self = shift;
    my $perl = shift;

    return() if not defined $perl;
    return $perl if -f $perl and -x _;

    # Build up a set of file names (not command names).
    if ($^O ne 'VMS') {
      $perl .= $Config{_exe}
        unless $perl =~ m/\Q$Config{_exe}$/i;
    }

    return $perl if -f $perl and -x _;
    return();
}


=head2 get_config

Returns a copy of the C<%Config::Config> hash of the
intepreter which was specified as a parameter to the
constructor.

The first time this method (or the get_inc method below)
is called, the perl binary is run. For subsequent calls
of this method, the information is cached.

=cut

sub get_config {
    my $self = shift;
    return $self->{config} if defined $self->{config};

    $self->{config} = $self->_infer_config($self->{perl});

    return $self->{config};
}

sub _infer_config {
    my $self = shift;
    my $perl = shift;
    my $code = <<'HERE';
use Config;
foreach my $k (keys %Config) {
 my $ek = $k;
 $ek =~ s/([\n\t\r%])/q{%}.ord($1).q{;}/ge;
 my $ev = $Config{$k};
 if (defined $ev) {
  $ev =~ s/([\n\t\r%])/q{%}.ord($1).q{;}/ge;
 } else {
  $ev = q{%-1;};
 }
 print qq{$ek\n$ev\n};
}
HERE

    warn "Running the following code:\n---$code\n---" if $self->{debug};

    $code =~ s/\s+$//;
    $code =~ s/\n/ /g;

    my @command = (
      $perl, '-e', $code
    );
    warn "Running the following command: '@command'" if $self->{debug};

    my $old_use_run = $IPC::Cmd::USE_IPC_RUN;
    $IPC::Cmd::USE_IPC_RUN = 1;
    my ($success, $error_code, undef, $buffer, $error) = IPC::Cmd::run(
        command => \@command,
    );
    $IPC::Cmd::USE_IPC_RUN = $old_use_run;
    

    warn "Returned buffer is:\n---\n".join("\n",@$buffer)."\n---" if $self->{debug};
    warn "Returned error buffer is:\n---\n".join("\n",@$error)."\n---" if $self->{debug};

    if (not $success) {
        croak(
            "Could not run the specified perl interpreter to determine \%Config. Error code (if any) was: $error_code. STDERR was (if any): ".join('', @$error)
        );
    }

    my %Config;
    my @data = split /\n/, join '', @$buffer;
    while (@data) {
        my $key = shift(@data);
        chomp $key;
        my $value = shift(@data);
        $value = '' if !defined $value; #in case of last value
        chomp $value;
        $key =~ s/%(\d+);/chr($1)/eg;
        if ($value eq '%-1;') {
            $value = undef;
        }
        else {
            $value =~ s/%(\d+);/chr($1)/eg;
        }
        $Config{$key} = $value;
    }

    return \%Config;
}


=head2 get_inc

Returns a copy of the C<@INC> array of the
intepreter which was specified as a parameter to the
constructor. B<Caveat:> This skips any references
(subroutines, C<ARRAY> refs, objects) in the C<@INC>
array because they cannot be reliably stringified!

The first time this method (or the get_config method avove)
is called, the perl binary is run. For subsequent calls
of this method, the information is cached.

=cut

sub get_inc {
    my $self = shift;
    return $self->{config} if defined $self->{inc};

    $self->{inc} = $self->_infer_inc($self->{perl});

    return $self->{inc};
}


sub _infer_inc {
    my $self = shift;
    my $perl = shift;
    my $code = <<'HERE';
foreach my $inc (@INC) {
  my $i = $inc;
  if (not ref($i)) {
    $i =~ s/([\n\t\r%])/q{%}.ord($1).q{;}/ge;
  }
  print qq{$i\n};
}
HERE
    warn "Running the following code:\n---$code\n---" if $self->{debug};

    $code =~ s/\s+$//;
    $code =~ s/\n/ /g;

    my @command = (
      $perl, '-e', $code
    );
    warn "Running the following command: '@command'" if $self->{debug};

    my $old_use_run = $IPC::Cmd::USE_IPC_RUN;
    $IPC::Cmd::USE_IPC_RUN = 1;
    my ($success, $error_code, undef, $buffer, $error) = IPC::Cmd::run(
        command => \@command,
    );
    $IPC::Cmd::USE_IPC_RUN = $old_use_run;

    warn "Returned buffer is:\n---\n".join("\n",@$buffer)."\n---" if $self->{debug};
    warn "Returned error buffer is:\n---\n".join("\n",@$error)."\n---" if $self->{debug};

    if (not $success) {
        croak(
            "Could not run the specified perl interpreter to determine \@INC. Error code (if any) was: $error_code. STDERR was (if any): ".join('', @$error)
        );
    }

    my @inc;
    my @data = split /\n/, join '', @$buffer;
    foreach my $line (@data) {
        chomp $line;
        if ($line eq '%-1;') {
            $line = undef;
        }
        else {
            $line =~ s/%(\d+);/chr($1)/eg;
        }
        push @inc, $line;
    }

    return \@inc;
}


1;
__END__

=head1 CAVEATS

This module cannot get the non-plain (i.e. non-string) entries of
the C<@INC> array!

=head1 SEE ALSO

You can use this module with L<ExtUtils::Installed> to get
information about perl installations that aren't currently
running.

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2010 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
