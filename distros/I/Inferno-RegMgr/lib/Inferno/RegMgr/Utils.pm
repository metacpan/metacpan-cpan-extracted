package Inferno::RegMgr::Utils;
use 5.010001;
use warnings;
use strict;
use utf8;
use Carp;

our $VERSION = 'v1.0.0';

use Export::Attrs;


sub quote :Export {
    my ($s) = @_;
    if ($s =~ / \s | ' | \A\z /xms) {
        $s =~ s/'/''/xmsg;
        $s = "'$s'";
    }
    return $s;
}

sub unquote :Export {
    my ($s) = @_;
    if ($s =~ s/\A'(.*)'\z/$1/xms) {
        $s =~ s/''/'/xmsg;
    }
    return $s;
}

sub attr :Export {
    my ($attr) = @_;
    my @s;
    while (my ($k, $v) = each %{ $attr || {} }) {
        push @s, sprintf '%s %s', quote($k), quote($v);
    }
    return join q{ }, @s;
}

sub parse_svc :Export {
    my ($s) = @_;
    state $qword = qr{( [^'\s]+ | '[^']*(?:''[^']*)*' )}xms;
    return ({}, undef) if $s eq q{};
    return (undef, 'no \\n at end') if $s !~ /\n\z/xms;
    my %svc;
    for my $line (split /\n/xms, $s) {
        my $errmsg = "can't parse service: $line";
        return (undef, $errmsg) if $line !~ s/\A$qword//xms;
        my $name = unquote($1);             ## no critic (ProhibitCaptureWithoutTest)
        my %attr;
        while (length $line) {
            return (undef, $errmsg) if $line !~ s/\s$qword\s$qword//xms;
            my ($attr, $value) = ($1, $2);  ## no critic (ProhibitCaptureWithoutTest)
            $attr{ unquote($attr) } = unquote($value);
        }
        $svc{$name} = \%attr;
    }
    return (\%svc, undef);
}

my $STDREF = qr{SCALAR|ARRAY|HASH|CODE|REF|GLOB|LVALUE}xms;
sub run_callback :Export {
    croak  'usage: run_callback( CB [, METHOD [, @ARGS]] )'    if @_ < 1;
    my ($cb, $method) = (shift, shift);
    my $cb_type
        = !ref($cb)                         ? 'CLASS'
        : ref($cb) eq 'CODE'                ? 'CODE'
        : ref($cb) !~ m{\A$STDREF\z}xmso    ? 'OBJECT'
        :                                     undef
        ;
    if ($cb_type eq 'CLASS' || $cb_type eq 'OBJECT') {
        $cb->$method(@_);
    }
    elsif ($cb_type eq 'CODE') {
        $cb->(@_);
    }
    else {
        croak qq{run_callback: wrong CB $cb};
    }
    return;
}



1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

Inferno::RegMgr::Utils - Internal module for use by other Inferno::RegMgr::*


=head1 VERSION

This document describes Inferno::RegMgr::Utils version v1.0.0


=head1 SYNOPSIS

 run_callback( \&sub );
 run_callback( 'CLASS', 'some_method' );
 run_callback( $obj, 'some_method', $foo, "bar" );


=head1 DESCRIPTION

Internal module for use by other Inferno::RegMgr::*.


=head1 INTERFACE 

=over

=item run_callback( CB, METHOD, ARGS )

Run callback in Perl6 style (see http://dev.perl.org/perl6/rfc/321.html).

 CB         REQUIRED. code ref OR object OR class name
 METHOD     REQUIRED. method name for CB
 ARGS       OPTIONAL. list with params for CB
 NOTE: METHOD required only if CB is object or class name.

Return: nothing.

=item quote()

=item unquote()

=item attr()

=item parse_svc()

Helpers to process service list used by registry server.


=back


=head1 DIAGNOSTICS

=over

=item C<< usage: run_callback( CB [, METHOD [, @ARGS]] ) >>

run_callback() was executed without params.

=item C<< run_callback: wrong CB ... >>

First param of run_callback() isn't one of:

 CODE ref
 OBJECT
 CLASS name


=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/powerman/perl-Inferno-RegMgr/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

L<https://github.com/powerman/perl-Inferno-RegMgr>

    git clone https://github.com/powerman/perl-Inferno-RegMgr.git

=head2 Resources

=over

=item * MetaCPAN Search

L<https://metacpan.org/search?q=Inferno-RegMgr>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/Inferno-RegMgr>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Inferno-RegMgr>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Inferno-RegMgr>

=item * CPANTS: A CPAN Testing Service (Kwalitee)

L<http://cpants.cpanauthors.org/dist/Inferno-RegMgr>

=back


=head1 AUTHOR

Alex Efros E<lt>powerman@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009-2010 by Alex Efros E<lt>powerman@cpan.orgE<gt>.

This is free software, licensed under:

  The MIT (X11) License


=cut
