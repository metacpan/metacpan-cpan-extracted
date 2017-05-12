package Device::USB::PCSensor::HidTEMPer::NTC::External;

use strict;
use warnings;
use Carp;
use Time::HiRes qw / sleep /;

use Device::USB::PCSensor::HidTEMPer::Sensor;
our @ISA = 'Device::USB::PCSensor::HidTEMPer::Sensor';

=head1

Device::USB::PCSensor::HidTEMPer::NTC::Internal - The HidTEMPerNTC external sensor

=head1 VERSION

Version 0.02

=cut

our $VERSION = 0.02;

=head1 SYNOPSIS

None

=head1 DESCRIPTION

This is the implementation of the HidTEMPerNTC external sensor.

=head2 CONSTANTS

=over 3

=item * MAX_TEMPERATURE

The highest temperature(150 degrees celsius) this sensor can detect.

=cut

use constant MAX_TEMPERATURE    => 150;

=item * MIN_TEMPERATURE

The lowest temperature(-50 degrees celsius) this sensor can detect.

=cut

use constant MIN_TEMPERATURE    => -50;

=item * INITIAL_GAIN

The initial gain value used to calculate voltage returned

=cut

use constant INITIAL_GAIN       => 1;

=item * CALIBRATION_VALUES

Values used to calculate Volt7705Calibration

=cut

use constant CALIBRATION_VALUES => [
    [ 0.0010888,    0.0012803,  0.000754167,    0.0009208333    ],
    [ 0.0012803,    0.0017002,  0.0009208333,   0.0012541667    ],
    [ 0.0017002,    0.002666,   0.0012541667,   0.0021125       ],
    [ 0.002666,     0.00522,    0.0021125,      0.0041666667    ],
    [ 0.00522,      0.0149,     0.0041666667,   0.012625        ],
    [ 0.0149,       0.04683,    0.012625,       0.0413333333    ],
    [ 0.04683,      0.21342,    0.0413333333,   0.2115416667    ],
    [ 0.21342,      0.36914,    0.2115416667,   0.346166667     ],
    [ 0.36914,      0.44121,    0.346166667,    0.4215416667    ],
    [ 0.44121,      0.65351,    0.4215416667,   0.6208333333    ],
    [ 0.65351,      0.92445,    0.6208333333,   0.91625         ],
    [ 0.92445,      1.08022,    0.91625,        1.1375          ],
    [ 1.08022,      1.8745,     1.1375,         1.91375         ],
    [ 1.8745,       1.9943,     1.91375,        2.07125         ],
    [ 1.9943,       2.4589,     2.07125,        2.72125         ],
];

=back

=head2 METHODS

=over 3

=item * new()

Returns a new External sensor object.

=cut
sub new
{
    my $class       = shift;
    
    # All devices are required to spesify the temperature range
    my $self        = $class->SUPER::new( @_ );
    
    # Initialize the gain, this will be automatically adjusted later on.
    $self->{gain}   = INITIAL_GAIN;
    $self->_write_gain( $self->{gain} );
    
    bless $self, $class;
    return $self;
}

=item * celsius()

Returns the current temperature from the device in celsius degrees.

=cut

sub celsius
{
    my $self        = shift;
    
    my @data        = ();
    my $counter     = 0;
    my $volt        = 0;
    my $key         = 0;
    my $temperature = 0;
    
    # Command 0x41 will return the following 8 byte result, repeated 4 times.
    # Position 0: Part one of the float number
    # Position 1: Part two of the float number
    # Position 2: Part three of the float number
    # Position 3: unused
    # Position 4: unused
    # Position 5: unused
    # Position 6: unused
    # Position 7: unused
    
    # This device may return 255*8 until it is ready for use.
    @data        = $self->{unit}->_read( 0x41 );
    $counter     = 0;

    READ: until ( $counter > 20 ){
                      next READ if $data[0] == 0xFF 
                                    && $data[1] == 0xFF
                                    && $data[2] == 0xFF;
                                    
                      # Caluculate returned reading
                      $volt = ( ( ( $data[0]-128 ) + ( $data[1] / 256 )  ) / 52.032520325203252 ) / $self->{gain};
                      
                      last READ if $self->_new_reading_needed( $volt ) == 0;
                  }continue{
                      $counter++;
                      sleep 0.2;
                      @data = $self->{unit}->_read( 0x41 );
                  }
    
    croak 'Invalid readings returned' if $counter >= 21;
    
    # Calculate key
    $key = $self->_volt_7705_calibration( $volt );
    
=pod

The formula used to calculate value based on a calibrated key value is
created using the Eureqa tool from Cornell Computational Synthesis Lab,
http://ccsl.mae.cornell.edu/eureqa.

Resulting in the use of this formula instead of the provided number list:
f(y)=66.7348/(66.7275/(67.8088 - 9.70353*log(0.000251309 + y*y)) - 0.21651)

If you find another formula that is more accurate please drop me a line. 
The data used can be found in the source code of this file.

=cut 

    $temperature = 66.7348 
                  / ( 66.7275 
                      / ( 67.8088 
                          - 
                          9.70353
                          * 
                          log( 0.000251309 
                               + ( $key
                                   * $key ) 
                          )
                    ) 
                    - 
                    0.21651 
                  );

    return $temperature;
}

# Calculate Volt7705Calibration
sub _volt_7705_calibration
{
    my $self        = shift;
    my ( $volt )    = @_;
    my $reference   = undef;
    
    # Select the correct values needed
    if( $volt <= 0.0010888 ){ 
        return -0.000334633; 
    }elsif( $volt <= 0.0012803 ){ 
        $reference = CALIBRATION_VALUES->[0]; 
    }elsif( $volt <= 0.0017002 ){
        $reference = CALIBRATION_VALUES->[1]; 
    }elsif( $volt <= 0.002666 ){ 
        $reference = CALIBRATION_VALUES->[2]; 
    }elsif( $volt <= 0.00522 ){
        $reference = CALIBRATION_VALUES->[3];
    }elsif( $volt <= 0.0149 ){ 
        $reference = CALIBRATION_VALUES->[4]; 
    }elsif( $volt <= 0.04683 ){ 
        $reference = CALIBRATION_VALUES->[5]; 
    }elsif( $volt <= 0.21342 ){
        $reference = CALIBRATION_VALUES->[6]; 
    }elsif( $volt <= 0.36914 ){ 
        $reference = CALIBRATION_VALUES->[7]; 
    }elsif( $volt <= 0.44121 ){ 
        $reference = CALIBRATION_VALUES->[8];
    }elsif( $volt <= 0.65351 ){
        $reference = CALIBRATION_VALUES->[9]; 
    }elsif( $volt <= 0.92445 ){ 
        $reference = CALIBRATION_VALUES->[10]; 
    }elsif( $volt <= 1.08022 ){
        $reference = CALIBRATION_VALUES->[11]; 
    }elsif( $volt <= 1.8745 ){
        $reference = CALIBRATION_VALUES->[12]; 
    }elsif( $volt <= 1.9943 ){
        $reference = CALIBRATION_VALUES->[13]; 
    }elsif( $volt <= 2.4589 ){
        $reference = CALIBRATION_VALUES->[14]; 
    }else{
        return 0.26235000000000008;
    }
    
    return (
        (
            $volt
            + 
            ( 
                ( 
                    ( ( $reference->[2] * $volt ) / $reference->[0] )
                    + 
                    (
                        (
                            ( ( $reference->[3] * $volt ) / $reference->[1] ) 
                            - 
                            ( ( $reference->[2] * $volt ) / $reference->[0] )
                        ) 
                        * 
                        ( 
                            ( $volt - $reference->[0] ) 
                            / 
                            ( $reference->[1] - $reference->[0] ) 
                        )
                    )
                ) 
                - 
                $volt 
            ) 
        ) / 0.0000041666666666666669
    ) / 1000;
}

# Returns 0 if the gain has not changed and a new reading is not needed.
sub _new_reading_needed
{
    my $self        = shift;
    my ( $volt )    = @_;
    
    # Safety filters  
    return 0 if ( $self->{gain} > 128 ) || ( $self->{gain} < 1 );
    return 0 if $self->{gain} % 2 != 0;
    
    # Adjust gain
    if( !defined $volt ){
        carp 'Undefined voltage';
    }elsif( $volt > ( 2.214 / $self->{gain} ) ) { 
        $self->{gain} = $self->{gain}*0.5;
        $self->_write_gain();
        return -1;
    }elsif( $volt < ( 0.984 / $self->{gain} ) ) {   
        $self->{gain} = $self->{gain}*2;
        $self->_write_gain();
        return 1;
    }else{ 
        return 0;
    }
    
    croak 'Could not recalculate gain';
}

# Write gain value to device
sub _write_gain
{
    $_[0]->{unit}->_write( 0x61 + ( log( $_[0]->{gain} ) / log(2) ) );
    sleep 0.2;
    $_[0]->{unit}->_write( 0x61 + ( log( $_[0]->{gain} ) / log(2) ) );
}

=back

=head1 INHERIT METHODS FROM

Device::USB::PCSensor::HidTEMPer::Sensor

=head1 DEPENDENCIES

This module internally includes and takes use of the following packages:

  use Carp;
  use Time::HiRes qw / sleep /;
  use Device::USB::PCSensor::HidTEMPer::Sensor;

This module uses the strict and warning pragmas. 

=head1 BUGS

Please report any bugs or missing features using the CPAN RT tool.

=head1 FOR MORE INFORMATION

None

=head1 AUTHOR

Magnus Sulland < msulland@cpan.org >

=head1 ACKNOWLEDGEMENTS

This code includes findings done by Robin B. Jensen, 
http://www.drunkardswalk.dk, when converting the received hex values into
volt.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2010-2011 Magnus Sulland

This program is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself.

=cut

1;

__END__

Temperature, Calibrated key
-50,712.066
-49,661.926
-48,615.656
-47,572.934
-46,533.466
-45,496.983
-44,463.24
-43,432.015
-42,403.104
-41,376.32
-40,351.495
-39,328.472
-38,307.11
-37,287.279
-36,268.859
-35,251.741
-34,235.826
-33,221.021
-32,207.242
-31,194.412
-30,182.46
-29,171.32
-28,160.932
-27,151.241
-26,142.196
-25,133.75
-24,125.859
-23,118.485
-22,111.589
-21,105.139
-20,99.102
-19,93.45
-18,88.156
-17,83.195
-16,78.544
-15,74.183
-14,70.091
-13,66.25
-12,62.643
-11,59.255
-10,56.071
-9,53.078
-8,50.263
-7,47.614
-6,45.121
-5,42.774
-4,40.563
-3,38.48
-2,36.517,
-1,34.665,
0,32.919,
1,31.27,
2,29.715,
3,28.246,
4,26.858,
5,25.547,
6,24.307,
7,23.135,
8,22.026,
9,20.977,
10,19.987,
11,19.044,
12,18.154,
13,17.31,
14,16.51
15,15.752
16,15.034
17,14.352
18,13.705
19,13.09
20,12.507
21,11.953
22,11.427
23,10.927
24,10.452
25,10
26,9.57
27,9.161
28,8.771
29,8.401
30,8.048
31,7.712
32,7.391
33,7.086
34,6.795
35,6.518
36,6.254
37,6.001
38,5.761
39,5.531
40,5.311
41,5.102
42,4.902
43,4.71
44,4.528
45,4.353
46,4.186
47,4.026
48,3.874
49,3.728
50,3.588
51,3.454
52,3.326
53,3.203
54,3.085
55,2.973
56,2.865
57,2.761
58,2.662
59,2.567
60,2.476
61,2.388
62,2.304
63,2.223
64,2.146
65,2.072
66,2
67,1.932
68,1.866
69,1.803
70,1.742
71,1.684
72,1.627
73,1.573
74,1.521
75,1.471
76,1.423
77,1.377
78,1.332
79,1.289
80,1.248
81,1.208
82,1.17
83,1.133
84,1.097
85,1.063
86,1.03
87,0.998
88,0.968
89,0.938
90,0.909
91,0.882
92,0.855
93,0.829
94,0.805
95,0.781
96,0.758
97,0.735
98,0.714
99,0.693
100,0.673
101,0.653
102,0.635
103,0.616
104,0.599
105,0.582
106,0.565
107,0.55
108,0.534
109,0.519
110,0.505
111,0.491
112,0.478
113,0.465
114,0.452
115,0.44
116,0.428
117,0.416
118,0.405
119,0.395
120,0.384
121,0.374
122,0.364
123,0.355
124,0.345
125,0.337
126,0.328
127,0.319
128,0.311
129,0.303
130,0.296
131,0.288
132,0.281
133,0.274
134,0.267
135,0.261
136,0.254
137,0.248
138,0.242
139,0.236
140,0.23
141,0.225
142,0.219
143,0.214
144,0.209
145,0.204
146,0.199
147,0.195
148,0.19
149,0.186
150,0.181
