#!/usr/bin/env perl

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

