# -*- perl -*-
BEGIN
{
    use strict;
    use lib './lib';
    use Test::More qw( no_plan );
    use File::Find;
    our @modules;
    File::Find::find(sub
    {
        return unless( /\.pm$/ );
        # print( "Checking file '$_' ($File::Find::name)\n" );
        $_ = $File::Find::name;
        s,^./lib/,,;
        s,\.pm$,,;
        s,/,::,g;
        push( @modules, $_ );
    }, qw( ./lib ) );
};

BEGIN
{
    use_ok( $_ ) for( @modules );
};

my $object = Markdown::Parser->new();
isa_ok( $object, 'Markdown::Parser' );

done_testing();

__END__
