use strict;

use Test::More;

BEGIN { push @INC, qw(blib/script) if -d 'blib' };

eval { require Pod::Parser } or
	plan skip_all => q(No Pod::Parser);

eval { require IO::ScalarArray } or
	plan skip_all => q(No IO::ScalarArray);

package File::Rename::Test::Parser;
our @ISA = qw(Pod::Parser);

sub command { return }
sub textblock { return }
sub interior_sequence { return }
sub verbatim {
    my ($parser, $paragraph) = @_;
    my $out_fh = $parser->output_handle();
    print $out_fh $paragraph;
}


package main;

my $generic = 'rename';
my $script = ($^O =~ m{Win} ? 'file-'.$generic : $generic);
eval { require($script) } or
    BAIL_OUT qq{require($script)};

my $inc_script = $INC{$script};
BAIL_OUT "\$INC($script) = '$inc_script', missing\n" 
    unless $inc_script and -e $inc_script;  

File::Rename::Test::Parser->new
    ->parse_from_file(	$inc_script,
	    		IO::ScalarArray->new(\my @verbatim) );

my @examples = grep /\s+$generic\s/, @verbatim;

#########################

# Insert your test code below, the Test::More module 
# is use()ed here so read its man page ( perldoc Test::More ) 
# for help writing this test script.

plan tests => 2 + (@examples || 1);
like( $inc_script, qr{/ $script \z}msx,
	"required $script is $inc_script");
ok( scalar(@examples) > 1, "enough examples in $inc_script" );
# Larry Wall wrote 2 examples in 1992!

unshift @INC, 't' if -d 't';
require 'testlib.pl';

for ( @examples ) {
    s/\n+\z//;
    my $example = $_;
    s/\A\s+$generic\s+//;
    
    my @args = split;
    for (@args) { s/\A'(.*)'\z/$1/; }

    my $dir = tempdir();
    create(qw(1 foo.bak baa));
    chdir $dir or die $!;
    mkdir 'my_new_dir' or die $!;

    if ( $args[-1] =~ /\A\*/ ) {
	my @glob = glob(pop @args);
	push @args, @glob;
    }

    my $ok = eval { main_argv( @args ); 1 }; 
    ok( $ok, "example:$example" );
    diag $@ unless $ok;

    chdir File::Spec->updir or die $!;
    File::Path::rmtree($dir) or die $!;
}
	
