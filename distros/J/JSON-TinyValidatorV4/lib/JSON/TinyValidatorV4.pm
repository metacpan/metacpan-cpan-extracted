package JSON::TinyValidatorV4;
$JSON::TinyValidatorV4::VERSION = '0.003';
use File::ShareDir 'dist_file';
use JavaScript::V8;
use Moo;

use strict;
use warnings;

has 'cx' => ( is => 'lazy' );

=head1 NAME

JSON::TinyValidatorV4 - JSON Validator for v4 JSON Schema

=head1 SYNOPSIS

 use JSON::TinyValidatorV4;
 use Data::Dumper;

 my $schema = {
     type       => 'object',
     properties => {
         latitude  => { type => 'number' },
         longitude => { type => 'number' }
     }
 };

 my $data = { longitude => -128.323746, latitude => -24.375870, elevation=> 23.1 };

 my $tv4 = JSON::TinyValidatorV4->new;

 print $tv4->validate( $data, $schema ), "\n";        # prints "1"
 print $tv4->validate( $data, $schema, 0, 1 ), "\n";  # prints "0"

 print Dumper( $tv4->validateResult( $data, $schema, 0, 1 ) );
 # prints:
 # $VAR1 = {
 #           'valid' => 0,
 #           'error' => {
 #                      'message' => 'Unknown property (not in schema)',
 #                      'dataPath' => '/elevation',
 #                       ...
 #                    },
 #           'missing' => []
 #         };

=head1 DESCRIPTION

This package is a wrapper for Tiny Validator. It uses json-schema draft v4
to validate simple values and complex objects. For details see also SEE ALSO.

=cut

sub _build_cx {
    my $cx = JavaScript::V8::Context->new();
    open( my $fh, "<", dist_file( 'JSON-TinyValidatorV4', 'tv4.min.js' ) ) or die "tv4.min.js: $!";
    $cx->eval( do { local $/; <$fh> } );
    close $fh;
    return $cx;
}

=pod

=head2 validate( $data, $schema, [ $checkRecursive=0, $banUnknownProperties=0 ] )

validates $data with $schema. $checkRecursive and $banUnknownProperties are false
by default. returns 0 or 1.

=cut

sub validate {
    my ( $self, @args ) = @_;
    $self->cx->bind( args => \@args );
    return $self->cx->eval('tv4.validate.apply(this,args)') // die $@;
}

=pod

=head2 validateResult( $data, $schema, [ $checkRecursive=0, $banUnknownProperties=0 ] )

validates $data with $schema. $checkRecursive and $banUnknownProperties are false
by default. returns an result hash:

 {
     valid   => 0,
     error   => {...},
     missing => [...]
 }

=cut

sub validateResult {
    my ( $self, @args ) = @_;
    $self->cx->bind( args => \@args );
    return $self->cx->eval('r={};tv4.validate.apply(r,args);r') // die $@;
}

=head1 SEE ALSO

 Tiny Validator at github: L<https://github.com/geraintluff/tv4>

=head1 AUTHORS

 Michael Langner, mila at cpan dot org

=head1 THANKS

This package uses an embedded copy of
Tiny Validator (L<https://github.com/geraintluff/tv4>)
to do all the validation work.

=head1 COPYRIGHT & LICENSE

Copyright 2015 Michael Langner, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut

!0;    # 3a59124cfcc7ce26274174c962094a20
