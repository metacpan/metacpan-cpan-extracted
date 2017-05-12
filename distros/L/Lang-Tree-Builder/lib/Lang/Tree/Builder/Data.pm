package Lang::Tree::Builder::Data;

use strict;
use warnings;
use Lang::Tree::Builder::Class;

our $VERSION = '0.01';


=head1 NAME

Lang::Tree::Builder::Data - Tree Data

=head1 SYNOPSIS

  use Lang::Tree::Builder::Parser;
  my $parser = new Lang::Tree::Builder::Parser();
  my $data = $parser->parseFile($datafile);
  foreach my $class ($data->classes()) {
      my $parent = $class->parent();
      my @args = $class->args();
  }

=head1 DESCRIPTION

=head2 new

  my $data = new Lang::Tree::Builder::Data;

Creates and returns a new instance of Data. Don't do this, the parser
does it for you.

=cut

sub new {
    my ($class) = @_;
    bless {
        classes => {},
    }, $class;
}

=head2 add

  $data->add($class);

C<$class> is a C<Lang::Tree::Builder::Class>.  Again the parser does this for you.
The C<$data> object merely caches the class object.
Note that this is only called for classes that are
declared in the config, not for classes that are just mentioned as argument
types for other constructors.

=cut

sub add {
    my ($self, $class) = @_;
    $self->{classes}{$class->name} = $class;
}

=head2 classes

returns an array of classes, or a reference to the same, sorted by name.

=cut

sub classes {
    my ($self) = @_;
    my @classes = @{$self->{classes}}{sort keys %{$self->{classes}}};
    return wantarray ? @classes : [@classes];
}

=head2 finalize

calls C<substantiate()> on each cached class.

=cut

sub finalize {
    my ($self) = @_;
    foreach my $key (keys %{$self->{classes}}) {
        $self->{classes}{$key}->substantiate();
    }
}

=head1 SEE ALSO

L<Lang::Tree::Builder>

=head1 AUTHOR

Bill Hails, E<lt>me@billhails.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Bill Hails

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
