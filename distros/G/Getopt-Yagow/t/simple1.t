#!/usr/local/perl -w

use strict;

use Getopt::Yagow;
use Test::More tests => 6;

my $opt = Getopt::Yagow->new;

ok(ref $opt eq 'Getopt::Yagow','new returns an Getopt::Yagow blessed object');
ok($opt =~ /=HASH/, 'new returns a hash ref');

my %opts_spec = (
                    'option0|opt0|0:s'  => '',
                    'option1|opt1|1=s'  => 'one',
                    'option2|opt2|2:s'  => 'two',
                    'option3|opt3|3:s@' => ['three','four','five'],
                    'option4|opt4|4:s%' => {one=>1,two=>2,three=>3},
                    'option5|opt5|5!'   => 0,
                    'option6|opt6|6:s'  => undef
                 );

&show_options_spec;

$opt = Getopt::Yagow->new( %opts_spec );

ok( 
    exists  $opt->{default} && 
    exists  $opt->{default}->{option0} && $opt->{default}->{option0} eq ''     &&
    exists  $opt->{default}->{option1} && $opt->{default}->{option1} eq 'one'  &&
    exists  $opt->{default}->{option2} && $opt->{default}->{option2} eq 'two'  &&
    exists  $opt->{default}->{option3} && ref $opt->{default}->{option3} eq 'ARRAY' &&
    exists  $opt->{default}->{option5} && 
    !exists $opt->{default}->{option6} && 
    exists $opt->{mandatory} && (grep {$_ eq 'option6'} @{$opt->{mandatory}}) &&
    exists $opt->{options} && ref $opt->{options} eq 'HASH' &&
    $opt->{options}->{option0} eq 'option0|opt0|0:s'  &&
    $opt->{options}->{option1} eq 'option1|opt1|1=s'  &&
    $opt->{options}->{option2} eq 'option2|opt2|2:s'  &&
    $opt->{options}->{option3} eq 'option3|opt3|3:s@' &&
    $opt->{options}->{option4} eq 'option4|opt4|4:s%' &&
    $opt->{options}->{option5} eq 'option5|opt5|5!'   &&
    $opt->{options}->{option6} eq 'option6|opt6|6:s' ,
    'new with hash as argument');

$opt = Getopt::Yagow->new( \%opts_spec );

ok( 
    exists  $opt->{default} && 
    exists  $opt->{default}->{option0} && $opt->{default}->{option0} eq ''     &&
    exists  $opt->{default}->{option1} && $opt->{default}->{option1} eq 'one'  &&
    exists  $opt->{default}->{option2} && $opt->{default}->{option2} eq 'two'  &&
    exists  $opt->{default}->{option3} && ref $opt->{default}->{option3} eq 'ARRAY' &&
    exists  $opt->{default}->{option5} && 
    !exists $opt->{default}->{option6} && 
    exists $opt->{mandatory} && (grep {$_ eq 'option6'} @{$opt->{mandatory}}) &&
    exists $opt->{options} && ref $opt->{options} eq 'HASH' &&
    $opt->{options}->{option0} eq 'option0|opt0|0:s'  &&
    $opt->{options}->{option1} eq 'option1|opt1|1=s'  &&
    $opt->{options}->{option2} eq 'option2|opt2|2:s'  &&
    $opt->{options}->{option3} eq 'option3|opt3|3:s@' &&
    $opt->{options}->{option4} eq 'option4|opt4|4:s%' &&
    $opt->{options}->{option5} eq 'option5|opt5|5!'   &&
    $opt->{options}->{option6} eq 'option6|opt6|6:s' ,
    'new with hash ref as argument');

$opt = Getopt::Yagow->new( \%opts_spec, ['pass_through'] );

ok( 
    exists  $opt->{configuration} && ref($opt->{configuration}) eq 'ARRAY' &&
    $opt->{configuration}[0] eq 'pass_through' && 
    exists  $opt->{default} && 
    exists  $opt->{default}->{option0} && $opt->{default}->{option0} eq ''     &&
    exists  $opt->{default}->{option1} && $opt->{default}->{option1} eq 'one'  &&
    exists  $opt->{default}->{option2} && $opt->{default}->{option2} eq 'two'  &&
    exists  $opt->{default}->{option3} && ref $opt->{default}->{option3} eq 'ARRAY' &&
    exists  $opt->{default}->{option5} && 
    !exists $opt->{default}->{option6} && 
    exists $opt->{mandatory} && (grep {$_ eq 'option6'} @{$opt->{mandatory}}) &&
    exists $opt->{options} && ref $opt->{options} eq 'HASH' && 
    $opt->{options}->{option0} eq 'option0|opt0|0:s'  &&
    $opt->{options}->{option1} eq 'option1|opt1|1=s'  &&
    $opt->{options}->{option2} eq 'option2|opt2|2:s'  &&
    $opt->{options}->{option3} eq 'option3|opt3|3:s@' &&
    $opt->{options}->{option4} eq 'option4|opt4|4:s%' &&
    $opt->{options}->{option5} eq 'option5|opt5|5!'   &&
    $opt->{options}->{option6} eq 'option6|opt6|6:s' ,
    'new with hash ref and array ref as argument');

$opt = Getopt::Yagow->new;
$opt->load_options( \%opts_spec,['no_pass_through'] );

ok( 
    exists  $opt->{configuration} && ref($opt->{configuration}) eq 'ARRAY' &&
    $opt->{configuration}[0] eq 'no_pass_through' && 
    exists  $opt->{default} && 
    exists  $opt->{default}->{option0} && $opt->{default}->{option0} eq ''     &&
    exists  $opt->{default}->{option1} && $opt->{default}->{option1} eq 'one'  &&
    exists  $opt->{default}->{option2} && $opt->{default}->{option2} eq 'two'  &&
    exists  $opt->{default}->{option3} && ref $opt->{default}->{option3} eq 'ARRAY' &&
    exists  $opt->{default}->{option5} && 
    !exists $opt->{default}->{option6} && 
    exists $opt->{mandatory} && (grep {$_ eq 'option6'} @{$opt->{mandatory}}) &&
    exists $opt->{options} && ref $opt->{options} eq 'HASH' &&
    $opt->{options}->{option0} eq 'option0|opt0|0:s'  &&
    $opt->{options}->{option1} eq 'option1|opt1|1=s'  &&
    $opt->{options}->{option2} eq 'option2|opt2|2:s'  &&
    $opt->{options}->{option3} eq 'option3|opt3|3:s@' &&
    $opt->{options}->{option4} eq 'option4|opt4|4:s%' &&
    $opt->{options}->{option5} eq 'option5|opt5|5!'   &&
    $opt->{options}->{option6} eq 'option6|opt6|6:s' ,
    'load_options');

#----------------------------------------------------------------------------------------
# FUNCTIONS.

sub show_options_spec
{
    while( my($opt_spec,$default) = each %opts_spec )
    {
        print "# $opt_spec => ";
        print '[', join(',',@$default), ']' if ref $default eq 'ARRAY';
        if( ref $default eq 'HASH' )
        {
            print '{'; while( my($k,$v)=each %$default ) { print "$k => $v,"}  print '}';
        }
        print $default if defined $default && ! ref $default;
        print "\n";
    }
}

__END__

=head1 NAME

simple1.t - Test file for Getopt::Yagow module.

=head1 SYNOPSIS

    % perl simple1.t

=head1 DESCRIPTION

Test file for Getopt/Yagow.pm module.

=head1 OPTIONS AND ARGUMENTS

=over 4

=item there is no options

=back
