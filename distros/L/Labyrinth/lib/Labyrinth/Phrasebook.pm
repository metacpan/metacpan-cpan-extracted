package Labyrinth::Phrasebook;

use warnings;
use strict;

use vars qw($VERSION);
$VERSION = '5.32';

=head1 NAME

Labyrinth::Phrasebook - Phrasebook Manager for Labyrinth

=head1 SYNOPSIS

  use Labyrinth::Phrasebook;

  my $pb = Labyrinth::Phrasebook->new($phrasebook);
  $pb->load($dictionary);
  my $result = $pb->get($entry);

=head1 DESCRIPTION

Using L<Data::Phrasebook>, this package acts as a simple wrapper for the 
Labyrinth framework.

=cut

# -------------------------------------
# Library Modules

use Data::Phrasebook;
use Labyrinth::Audit;
use Labyrinth::Writer;

# -------------------------------------
# Variables

my %pbcache;

# -------------------------------------
# The Public Interface Subs

=head1 FUNCTIONS

=head2 Constructor

=over 4

=item new()

Create a new Phrasebook object.

=back

=cut

sub new {
    my ($self, $phrasebook, $dict) = @_;

    Croak("Cannot read configuration file [$phrasebook]\n")  unless(-r $phrasebook);

    my $pb = Data::Phrasebook->new(
        class  => 'Plain',
        loader => 'Ini',
        file   => $phrasebook
    );

    Croak("Cannot access configuration file [$phrasebook]\n")   unless($pb);

    # set dictionary if not using default
    $pb->dict($dict)    if($dict);

    # set parameter pattern
    $pb->delimiters( qr{ \$(\w+) }x, 1 );

    # create an attributes hash
    my $atts = { 'pb' => $pb };

    # create the object
    bless $atts, $self;
    return $atts;
}

=head2 Methods

=over 4

=item load

Reset primary dictionary.

=cut

sub load {
    my ($self, $section) = @_;
    $self->{pb}->dict( $section )   if($section);
    return $self->{pb}->dict;
}

=item get

Gets an entry from the current section or from the default section if
entry doesn't exist in the current section.

=cut

sub get {
    my ($self, $key, $hash) = @_;
    my $crypt = join('', map { "$_=$hash->{$_}" } grep {$hash->{$_}} keys %$hash);

    return $pbcache{$key}{$crypt}   if($pbcache{$key}{$crypt});

    my $val = $self->{pb}->fetch( $key, $hash );
    Croak("Unknown key phrase [$key]\n")    unless($val);
    $val =~ s/\n|\t/ /sg;

#    # parse any given parameters
#    if($hash) {
#        for my $name (keys %$hash) {
#            LogDebug("get: name=[$name], value=[$hash->{$name}]");
#            $hash->{$name} ||= '';
#            $val =~ s/\$$name/$hash->{$name}/g;
#        }
#    }

#    $val =~ s/\$\w+//g; # remove unparsed parameters
    $pbcache{$key}{$crypt} = $val;
    return $val;
}

sub DESTROY {1}

1;

__END__

=back

=head1 SEE ALSO

  Data::Phrasebook
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
