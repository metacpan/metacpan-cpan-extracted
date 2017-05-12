package Locale::Tie;

our $DATE = '2014-10-23'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict;
no strict 'refs';
use warnings;

use POSIX qw();

use Exporter qw(import);
our @EXPORT_OK = qw(
  $LANG

  $LC_ALL
  $LC_ADDRESS
  $LC_COLLATE
  $LC_CTYPE
  $LC_IDENTIFICATION
  $LC_MEASUREMENT
  $LC_MESSAGES
  $LC_MONETARY
  $LC_NAME
  $LC_NUMERIC
  $LC_PAPER
  $LC_TELEPHONE
  $LC_TIME
);


our $LANG             ; tie $LANG             , 'Locale::Tie::SCALAR', 'LC_ALL'            or die "Can't tie \$LANG";
our $LC_ALL           ; tie $LC_ALL           , 'Locale::Tie::SCALAR', 'LC_ALL', 1         or die "Can't tie \$LC_ALL";
our $LC_ADDRESS       ; tie $LC_ADDRESS       , 'Locale::Tie::SCALAR', 'LC_ADDRESS'        or die "Can't tie \$LC_ADDRESS";
our $LC_COLLATE       ; tie $LC_COLLATE       , 'Locale::Tie::SCALAR', 'LC_COLLATE'        or die "Can't tie \$LC_COLLATE";
our $LC_CTYPE         ; tie $LC_CTYPE         , 'Locale::Tie::SCALAR', 'LC_CTYPE'          or die "Can't tie \$LC_CTYPE";
our $LC_IDENTIFICATION; tie $LC_IDENTIFICATION, 'Locale::Tie::SCALAR', 'LC_IDENTIFICATION' or die "Can't tie \$LC_IDENTIFICATION";
our $LC_MEASUREMENT   ; tie $LC_MEASUREMENT   , 'Locale::Tie::SCALAR', 'LC_MEASUREMENT'    or die "Can't tie \$LC_MEASUREMENT";
our $LC_MESSAGES      ; tie $LC_MESSAGES      , 'Locale::Tie::SCALAR', 'LC_MESSAGES'       or die "Can't tie \$LC_MESSAGES";
our $LC_MONETARY      ; tie $LC_MONETARY      , 'Locale::Tie::SCALAR', 'LC_MONETARY'       or die "Can't tie \$LC_MONETARY";
our $LC_NAME          ; tie $LC_NAME          , 'Locale::Tie::SCALAR', 'LC_NAME'           or die "Can't tie \$LC_NAME";
our $LC_NUMERIC       ; tie $LC_NUMERIC       , 'Locale::Tie::SCALAR', 'LC_NUMERIC'        or die "Can't tie \$LC_NUMERIC";
our $LC_PAPER         ; tie $LC_PAPER         , 'Locale::Tie::SCALAR', 'LC_PAPER'          or die "Can't tie \$LC_PAPER";
our $LC_TELEPHONE     ; tie $LC_TELEPHONE     , 'Locale::Tie::SCALAR', 'LC_TELEPHONE'      or die "Can't tie \$LC_TELEPHONE";
our $LC_TIME          ; tie $LC_TIME          , 'Locale::Tie::SCALAR', 'LC_TIME'           or die "Can't tie \$LC_TIME";

{
    package Locale::Tie::SCALAR;
    use Carp;

    sub TIESCALAR {
        bless [$_[1], $_[2]], $_[0];
    }

    sub FETCH {
        my $res = POSIX::setlocale(&{"POSIX::$_[0][0]"});
        if ($res =~ /;/) {
            if ($_[0][1]) {
                # hashify
                $res = { map {/(.+)=(.*)/} (split /;/, $res) };
            } else {
                # just grab the first
                ($res) = $res =~ /=([^;]+)/;
            }
        }
        $res;
    }

    sub STORE {
        unless (POSIX::setlocale(&{"POSIX::$_[0][0]"}, $_[1])) {
            carp "Can't setlocale($_[0][0], $_[1]): $!";
        }
    }
}

1;
#ABSTRACT: Get/set locale via (localizeable) variables

__END__

=pod

=encoding UTF-8

=head1 NAME

Locale::Tie - Get/set locale via (localizeable) variables

=head1 VERSION

This document describes version 0.03 of Locale::Tie (from Perl distribution Locale-Tie), released on 2014-10-23.

=head1 SYNOPSIS

 use Locale::Tie qw($LANG $LC_ALL $LC_TIME); # ...
 say "Current locale is ", $LANG; # -> en_US.UTF-8
 {
     local $LANG = 'id_ID';
     printf "%.2f\n", 12.34;  # -> 12,34
 }
 printf "%.2f\n", 12.34; # -> 12.34

=head1 DESCRIPTION

This module is inspired by L<File::chdir>, using a tied scalar variable to
get/set stuffs. One benefit of this is being able to use Perl's "local" with it,
effectively setting something locally.

=head1 EXPORTS

They are not exported by default, but exportable.

=head2 $LANG => str

Alias for $LC_ALL, but won't hashify.

=head2 $LC_ALL => str | hash

Return current locale as string. If different parts use different locale (e.g.
LC_COLLATE uses one locale and LC_CTYPE uses another) will return a hash, e.g.:

 {
   LC_ADDRESS        => "en_US.UTF-8",
   LC_COLLATE        => "en_US.UTF-8",
   LC_CTYPE          => "en_US.UTF-8",
   LC_IDENTIFICATION => "en_US.UTF-8",
   LC_MEASUREMENT    => "en_US.UTF-8",
   LC_MESSAGES       => "id_ID.UTF-8",
   LC_MONETARY       => "en_US.UTF-8",
   LC_NAME           => "en_US.UTF-8",
   LC_NUMERIC        => "C",
   LC_PAPER          => "en_US.UTF-8",
   LC_TELEPHONE      => "en_US.UTF-8",
   LC_TIME           => "en_US.UTF-8",
 }

=head1 $LC_ADDRESS

=head1 $LC_COLLATE

=head1 $LC_CTYPE

=head1 $LC_IDENTIFICATION

=head1 $LC_MEASUREMENT

=head1 $LC_MESSAGES

=head1 $LC_MONETARY

=head1 $LC_NAME

=head1 $LC_NUMERIC

=head1 $LC_PAPER

=head1 $LC_TELEPHONE

=head1 $LC_TIME

=head1 SEE ALSO

L<POSIX>

L<Locale::Scope>

Other modules with the same concept: L<File::chdir>, L<File::umask>,
L<System::setuid>.

L<autolocale> which uses L<Variable::Magic> (similar to tie technique) to
automatically setlocale() when entry C<< $ENV{LANG} >> is set.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Locale-Tie>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Locale-Tie>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Locale-Tie>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
