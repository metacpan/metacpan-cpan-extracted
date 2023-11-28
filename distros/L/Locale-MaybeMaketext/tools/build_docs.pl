#!perl
use strict;
use warnings;
use vars;
use File::Basename();
use File::Spec();
use File::Find();
use File::Path();
use Pod::Simple::XHTML;

my $base_path = File::Spec->catdir( File::Basename::dirname( File::Spec->rel2abs(__FILE__) ), File::Spec->updir() );

# check where we are looking for Perl files
my $source_path = File::Spec->catdir( $base_path, qw{lib} );
if ( !-d $source_path ) { die( sprintf( 'Could not find source directory at %s', $source_path ) . "\n" ); }
my $source_length = length($source_path);

# check where we expect to be able to save the output.
my $documentation_path = File::Spec->catdir( $base_path, q{docs} );
if ( !-d $documentation_path ) {
    die( sprintf( 'Could not find documentation directory at %s', $documentation_path ) . "\n" );
}
my $documentation_path_length = length($documentation_path);
my $pod_convertor             = Pod::Simple::XHTML->new;
my ( $output_file, $html, $output_handle, $directory_check, %directories_checked );

$pod_convertor->index(1);    # enable index
$pod_convertor->html_css('style.css');
$pod_convertor->anchor_items(0);

my @files;
File::Find::find(
    {
        'wanted' => sub {
            if ( -f $File::Find::name && check_if_file_is_perl($File::Find::name) ) { push @files, $File::Find::name; }
            1;
        },
    },
    ($source_path)
);

for my $current_file (@files) {
    if ( substr( $current_file, 0, $source_length ) ne $source_path ) {
        warn( sprintf( '%s is outside our source directory %s', $current_file, $source_path ) . "\n" );
        next;
    }
    if ( $current_file =~ /\.pm\z/ ) {    # does it look like a package
        $output_file = File::Spec->catfile(
            $documentation_path,
            substr( $current_file, $source_length + 1, -3 )    ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
        ) . '.html';
        check_directories_exist($output_file);
        $pod_convertor->output_string( \$html );
        $pod_convertor->parse_file($current_file);
        open $output_handle, '>', $output_file or die( sprintf( 'Cannot open %s: %s', $output_file, $! ) . "\n" );
        print {$output_handle} $html;
        close $output_handle or die( sprintf( 'Cannot close %s', $output_file ) . "\n" );
        print sprintf( 'Generated %s', $output_file ) . "\n";
    }
}

sub check_directories_exist {
    my ($file) = @_;
    $directory_check = File::Basename::dirname($file);
    if ( !$directories_checked{$directory_check} ) {
        if ( !-d $directory_check ) {
            my @directories = File::Spec->splitdir( substr( $directory_check, $documentation_path_length + 1 ) );
            my @from_top    = ();
            foreach (@directories) {
                push @from_top, $_;
                my $rebuild = File::Spec->catfile( $documentation_path, @from_top );
                if ( !$directories_checked{$rebuild} ) {
                    if ( !-d $rebuild ) {
                        File::Path::make_path($rebuild);
                    }
                    $directories_checked{$rebuild} = 1;
                }
            }
        }
        $directories_checked{$directory_check} = 1;
    }
    return 1;
}

sub check_if_file_is_perl {
    my ($file) = @_;

    # check common suffixes.
    if ( $file =~ /\.(?:pl|pm|t)\z/i ) {
        return 1;
    }
    my ( $file_handle, $first_line );
    if ( !open( $file_handle, '<', $file ) ) {
        warn( sprintf( 'Cannot open %s: %s . Skipping!', $file, $! ) . "\n" );
        return 0;
    }
    $first_line = <$file_handle>;
    close $file_handle or die( sprintf( 'Cannot close %s', $file ) . "\n" );
    if ( !$first_line ) {
        return 0;
    }

    # is it a batch file starting with --[*]-Perl-[*]-- ?
    if ( $file =~ /\.bat\z/i ) {
        if ( $first_line =~ /--[*]-Perl-[*]--/ ) {
            return 1;
        }
    }

    # is the first line a she-bang mentioning perl anywhere?
    if ( $first_line =~ /\A#!.*perl/ ) {
        return 1;
    }
    return 0;
}

