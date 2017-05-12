package EPublisher::Target::Plugin::Text;

# ABSTRACT: Use Ascii text as a target for EPublisher

use strict;
use warnings;

use Carp;
use File::Basename;
use File::Temp;
use IO::String;
use Pod::Text;

use EPublisher;
use EPublisher::Target::Base;
our @ISA = qw(EPublisher::Target::Base);

our $VERSION = 0.02;
our $DEBUG   = 0;

sub deploy {
    my ($self) = @_;
    
    my $pods     = $self->_config->{source} || [];
    my $width    = $self->_config->{width} || 78;
    my $sentence = $self->_config->{sentence};
    my $output   = $self->_config->{output};

    if ( !$output ) {
        my $fh = File::Temp->new;
        $output = $fh->filename;
    }

    my $io     = IO::String->new( join "\n\n", map{ $_->{pod} }@{$pods} );
    my $parser = Pod::Text->new( sentence => $sentence, width => $width );

    $parser->parse_from_filehandle( $io, $output );
    
    return $output;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

EPublisher::Target::Plugin::Text - Use Ascii text as a target for EPublisher

=head1 VERSION

version 1.21

=head1 SYNOPSIS

  use EPublisher::Target;
  my $Text = EPublisher::Target->new( { type => 'Text' } );
  $Text->deploy;

=head1 NAME

EPublisher::Target::Plugin::Text - Use Ascii text as a target for EPublisher

=head1 VERSION

version 0.4

=head1 METHODS

=head2 deploy

creates the output.

  $Text->deploy;

=head2 testresult

=head1 YAML SPEC

  TextTest:
    source:
      #...
    target:
      type: Text
      output: /path/to/test.txt

=head1 COPYRIGHT & LICENSE

Copyright 2012 Renee Baecker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms of Artistic License 2.0.

=head1 AUTHOR

Renee Baecker (E<lt>module@renee-baecker.deE<gt>)

=head1 AUTHOR

Renee Baecker <module@renee-baecker.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 AUTHOR

Renee Baecker <module@renee-baecker.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
