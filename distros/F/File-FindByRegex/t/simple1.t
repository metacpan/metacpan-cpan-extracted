#!C:\Perl\bin\perl.exe -w

use strict;
use vars qw($die_trapped);

use File::FindByRegex;
use Test::More tests => 11;

# 
# $SIG{__DIE__} = sub { $die_trapped = 1; };
# 
# $die_trapped = 0;
# my $find = File::FindByRegex->new();
# 
# ok($die_trapped==1,'Incorrect syntax in call');

eval { File::FindByRegex->new(); };
ok( $@ =~ /^Wrong arguments/, 'Test no arguments in new');

eval 
{ 
    File::FindByRegex->new( {} );
};
ok( $@ =~ /-srcdir and -tardir are mandatory/, 'Hash ref w/o members');

my $find = File::FindByRegex->new( { -srcdir => ['foo'], -tardir => 'bar' } );
ok( ref($find) eq 'File::FindByRegex', 'Test mandatory arguments');

$find = File::FindByRegex->new( -srcdir => ['foo'], -tardir => 'bar' );
ok( ref($find) eq 'File::FindByRegex', 'Hash members as arguments');

my %args = ( -srcdir => ['foo'], -tardir => 'bar' );
$find = File::FindByRegex->new(%args);
ok( ref($find) eq 'File::FindByRegex', 'Hash as argument');

use Config;
use File::Spec::Functions qw(tmpdir);

# installprivlib == C:\Perl\lib en Win32
# installsitelib == C:\Perl\site\lib en Win32

my($tardir,%dirs_explain,%files_explain,$pathsep,$B,$UNIVERSAL,$perl,@perlfaq,@perlsyn,@config);

$tardir = File::Spec->catfile(tmpdir, 'findbyregex');

$pathsep = quotemeta(File::Spec->canonpath('/'));
#print "$pathsep\n"; die;

$B = undef;
$find = File::FindByRegex->new( 

    -srcdir => [$Config{installprivlib},$Config{installsitelib}],
    -tardir => $tardir,

    -callbacks => {                       
                      qr/($pathsep)B$/oi => sub { my $this=shift; $B = $this->{-abspathn}; },
                      qr/($pathsep)UNIVERSAL.pm$/oi => sub { my $this=shift; $UNIVERSAL = $this->{-abspathn}; },
                      qr/($pathsep)pod($pathsep)perl.pod$/oi => sub { my $this=shift; $perl = $this->{-abspathn}; }
                  },

    -ignore => [ qr/.+?\.pod/oi ],

    -excepts => [ 
                    qr/($pathsep)pod($pathsep)perl\.pod$/oi,
                    qr/($pathsep)pod($pathsep)perlfaq\.pod$/oi
                ]

)->travel_tree;

undef &File::FindByRegex;
sub File::FindByRegex::post_match
{
    my $this = shift;

    $dirs_explain{$this->{-abspathn}} = $this->{-explain} if -d $this->{-abspathn};
    $files_explain{$this->{-abspathn}} = $this->{-explain} if -f $this->{-abspathn};
}

ok( $B && $dirs_explain{$B}==4, 'Test callback for directory and value 4 of -explain');

ok( $UNIVERSAL && $files_explain{$UNIVERSAL}==4,'Test callback for files and value 4 of -explain');

ok( $perl && $files_explain{$perl}==7,'Test value 7 of -explain code');

@perlfaq = grep { /($pathsep)pod($pathsep)perlfaq\.pod$/oi } keys %files_explain ;
ok($files_explain{$perlfaq[0]} == 3,'Test value 3 of -explain code');

@perlsyn = grep { /($pathsep)pod($pathsep)perlsyn\.pod$/oi } keys %files_explain ;
ok($files_explain{$perlsyn[0]} == 1,'Test value 1 of -explain code');

@config = grep { /($pathsep)Config\.pm$/oi } keys %files_explain ;
ok($files_explain{$config[0]} == 0,'Test value 0 of -explain code');

__END__

=head1 NAME

simple1.t - Test file for File::FindByRegex module.

=head1 SYNOPSIS

    % perl simple1.t

=head1 DESCRIPTION

Test file for File/FindByRegex.pm module.

=head1 OPTIONS AND ARGUMENTS

=over 4

=item there is no options

=back

Tratamiento sobre directorios.
Argumentos opcionales y obligatorios.
Mas de un directorio en -srcdir
