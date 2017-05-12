package Inline::Basic;

use strict;
use vars qw($VERSION);
$VERSION = '0.01';

use base qw(Inline);

use IO::Scalar;
use Language::Basic;

sub _croak { require Carp; Carp::croak(@_) }

sub register {
    return {
	language => 'Basic',
	aliases  => [ qw(basic) ],
	type     => 'interpreted',
	suffix   => 'pl',
    };
}

sub validate { }

sub build {
    my $self = shift;
    my $prog = Language::Basic::Program->new;
    my $code = $self->{API}->{code};
    for my $line (split /\n/, $code) {
	$prog->line($line);
    }
    my $path = "$self->{API}->{install_lib}/auto/$self->{API}->{modpname}";
    $self->mkpath($path) unless -d $path;

    # Catching code to $script
    tie *STDOUT, 'IO::Scalar', \my $script;
    $prog->output_perl;
    untie *STDOUT;

    # Pre-format it
    $script =~ s/^.*# Subroutine Definitions\n#\n//s;
    $script =~ s/sub (\w+)_fun/"sub FN" . uc($1)/eg;

    {
	package Inline::Basic::Tester;
	eval $script;
    }
    _croak "Basic build failed: $@" if $@;

    my $obj = $self->{API}->{location};
    open BASIC_OBJ, "> $obj" or _croak "$obj: $!";
    print BASIC_OBJ $script;
    close BASIC_OBJ;
}

sub load {
    my $self = shift;
    my $obj = $self->{API}->{location};

    open BASIC_OBJ, "< $obj" or _croak "$obj: $!";
    my $code = do { local $/; <BASIC_OBJ> };
    close BASIC_OBJ;

    eval "package $self->{API}->{pkg};\n$code";
    _croak "Can't load Basic module $obj: $@" if $@;
}

sub info { }


1;
__END__

=head1 NAME

Inline::Basic - Write Perl subroutines in Basic

=head1 SYNOPSIS

  use Inline 'Basic';

  print "1 + 5 = ", FNA(1), "\n";
  print "2 * 10 = ", FNB(2), "\n";

  __END__
  __Basic__
  010 DEF FNA(X) = INT(X + 5)
  020 DEF FNB(X) = INT(X * 10)

=head1 DESCRIPTION

Inline::Basic allows you to include Basic code in your Perl
program. Currently only function definitions in Basic is supported.

See L<Inline> for details about Inline API.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Inline>, L<Language::Basic>

=cut
