package Labyrinth::Constraints;

use warnings;
use strict;

use vars qw($VERSION $AUTOLOAD @ISA @EXPORT);
$VERSION = '5.32';

=head1 NAME

Labyrinth::Constraints - Basic Constraint Handler for Labyrinth

=head1 DESCRIPTION

Provides basic constraint methods used within Labyrinth.

=cut

#----------------------------------------------------------------------------
# Libraries

use Labyrinth::Variables;

#----------------------------------------------------------------------------
# Exporter Settings

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
    ddmmyy      valid_ddmmyy        match_ddmmyy
    url         valid_url           match_url
);

#----------------------------------------------------------------------------
# Subroutines

=head1 FUNCTIONS

=head2 ddmmyy

Validates simple day-month-year date strings.

=over 4

=item ddmmyy

=item valid_ddmmyy

=item match_ddmmyy

=back

=cut

sub ddmmyy {
    my %params = @_;
    return sub {
        my $self = shift;
        $self->set_current_constraint_name('ddmmyy');
        $self->valid_ddmmyy(\%params);
    }
}

my %mon = ( 1=>31,2=>29,3=>31,4=>30,5=>31,6=>30,7=>31,8=>31,9=>30,10=>31,11=>30,12=>31 );

sub valid_ddmmyy {
    my ($self,$text) = @_;
    return 0    unless($text);

    my @part = $text =~ m< ^ (\d{2,2}) [-/.] (\d{2,2}) [-/.] (\d{4,4}) $ >x;
    return 0    unless(@part == 3);

    return 0    if($part[2] < 1900 && $part[0] > 9999);
    return 0    if($part[1] < 1    && $part[0] > 12);
    return 0    if($part[0] < 1    && $part[0] > $mon{$part[1]});
    return 0    if($part[0] > 28   && $part[1] == 2 && $part[2] % 4 != 0);    # crude, but may surfice

    return 1;
}

sub match_ddmmyy {
    my ($self,$text) = @_;
    return unless defined $text;
    return $text    if($text =~ m< ^ \d{2,2} [-/.] \d{2,2} [-/.] \d{4,4} $ >x);
    return;
}

=head2 url

Validates simple URL patterns.

=over 4

=item url

=item valid_url

=item match_url

=back

=cut

sub url {
    my %params = @_;
    return sub {
        my $self = shift;
        $self->set_current_constraint_name('url');
        $self->valid_url(\%params);
    }
}

sub match_url {
    my ($self,$text) = @_;
    return                      unless($text);

    my ($url) = $text =~ /^($settings{urlregex})$/x;

    return                      unless($url);
    $text = 'http://' . $text   unless($text =~ m!^\w+://!);
    return $text;
}

sub AUTOLOAD {
    my $name = $AUTOLOAD;

    no strict qw/refs/;

    $name =~ m/^(.*::)(valid_|RE_)(.*)/;

    my ($pkg,$prefix,$sub) = ($1,$2,$3);

    # Since all the valid_* routines are essentially identical we're
    # going to generate them dynamically from match_ routines with the same names.
    if ((defined $prefix) and ($prefix eq 'valid_')) {
        return defined &{$pkg.'match_' . $sub}(@_) ? 1 : 0;
    }
}

1;

__END__

=head1 SEE ALSO

  Labyrinth

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2015 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
