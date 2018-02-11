use strict;
use warnings;
use lib 'lib';
use feature qw(say);
use Data::Dumper;
use File::Basename;
use File::Find::Rule;
use File::Slurper 'read_text';
use File::Spec;
use Getopt::Long;
use Test::Exception;
use Test::More;
use YAML qw(LoadFile);
use utf8;
use feature "unicode_strings";

# nicer output for diag and failures, see
# http://perldoc.perl.org/Test/More.html#CAVEATS-and-NOTES
my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(UTF-8)";
binmode $builder->failure_output, ":encoding(UTF-8)";
binmode $builder->todo_output,    ":encoding(UTF-8)";

my $af_path = dirname(__FILE__) . '/../../address-formatting';

my $path = $af_path . '/testcases/';
my $input_country;
my $verbose = 0;

GetOptions (
    'country:s'  => \$input_country,
    'verbose'    => \$verbose,
);
if ( $input_country ){
    $input_country = lc($input_country);
}

ok(1);

if ( -d $path ){

    my $conf_path = $af_path . '/conf/';

    my @files = File::Find::Rule->file()->name( '*.yaml' )->in( $path );

    ok(scalar(@files), 'found at least one yaml file');

    my $CLASS = 'Geo::Address::Formatter';
    use_ok($CLASS);
    my $GAF = $CLASS->new( conf_path => $conf_path );


    # check the conf file for formatting errors
    my $conffile = $conf_path . 'countries/worldwide.yaml';
    ok(-e $conffile, 'found worldwide conf file');

    # escaped parens and \d need to be double escaped for python
    my $no_bad_parens = 1;
    open my $FH, "<:encoding(UTF-8)", $conffile
        or die "unable to open $conffile $!";
    while (my $line = <$FH>){
        next if ($line =~ m/^\s*#/);
        my @probchars = ('\(', '\)', 'd');
        foreach my $c (@probchars){
            if ($line =~ m/\\$c/ && $line !~ m/\\\\$c/){
                warn $line;
                $no_bad_parens = 0;
                last; # bail out
            }
        }
    }
    close $FH;
    ok($no_bad_parens == 1, 'no badly escaped parens in worldwide conf file');


    # ok, time to actually run the country tests
    sub _one_testcase {
        my $country    = shift;
        my $rh_testcase = shift;

        my $expected = $rh_testcase->{expected};
        my $actual = $GAF->format_address($rh_testcase->{components});

        #warn "e1 $expected\n";
        #warn "a1 $actual\n";
        if (0) { # turn on for char by char comparison
            my @e = (split//, $expected);
            my @a = (split//, $actual);
            my $c = 0;
            foreach my $char (@e){
                if ($e[$c] eq $a[$c]){
                    warn "same $c same $a[$c]";
                } else {
                    warn "not same $c " . $e[$c] . ' ' . $a[$c] . "\n";
                }
                $c++;
            }
            #$expected =~ s/\n/, /g;
            #$actual =~ s/\n/, /g;
            #warn "e2 $expected\n";
            #warn "a2 $actual\n";
        }

        is(
          $actual,
          $expected,
          $country . ' - ' . ( $rh_testcase->{description} || 'no description set' )
        );
    }

    foreach my $filename (@files){

        my $country = basename($filename);
        $country =~ s/\.\w+$//; # us.yaml => us

        if (defined($input_country) && $input_country){
            if ($country ne $input_country){
                if ($verbose){
                    warn "skipping $country tests";
                }
                next;
            }
        }

        my @a_testcases = ();
        lives_ok {
            @a_testcases = LoadFile($filename);
        } "parsing file $filename";

        {
          my $text = read_text($filename);

          ## example "Stauffenstra\u00dfe" which should be "Stauffenstraße"
          if ( $text =~ m/\\u00/ ){
              unlike(
                $text,
                qr!\\u00!,
                'don\'t use Javascript utf8 encoding, use characters directly'
             );
          }

          if ( $text =~ m/\t/ ){
              unlike(
                $text,
                qr/\t/,
                'there is a TAB in the YAML file. That will cause parsing errors'
              );
          }
          if ( $text !~ m/\n$/ ){
              like(
                $text,
                qr!\n$!,
                'file doesnt end in newline. This will cause parsing errors'
             );
          }
          if ( $text =~ /:\s*0/ ){
              like(
                $text,
                qr!:s\*0!,
                'zero unquoted. The PHP YAML parser will convert 0012 to 12'
              );
          }

        }
        foreach my $rh_testcase (@a_testcases){
            _one_testcase($country, $rh_testcase);
        }
    }
}

done_testing();
