# -*- perl -*-
BEGIN
{
    use strict;
    use lib './lib';
    use Test::More qw( no_plan );
};

# To build the list of modules:
# find ./lib -type f -name "*.pm" -print | xargs perl -lE 'my @f=sort(@ARGV); for(@f) { s,./lib/,,; s,\.pm$,,; s,/,::,g; substr( $_, 0, 0, q{use ok( ''} ); $_ .= q{'' );}; say $_; }'
BEGIN
{
    use ok( 'MM::Const' );
    use ok( 'MM::Table' );
    use ok( 'Mail::Make' );
    use ok( 'Mail::Make::Body' );
    use ok( 'Mail::Make::Body::File' );
    use ok( 'Mail::Make::Body::InCore' );
    use ok( 'Mail::Make::Entity' );
    use ok( 'Mail::Make::Exception' );
    use ok( 'Mail::Make::GPG' );
    use ok( 'Mail::Make::Headers' );
    use ok( 'Mail::Make::Headers::ContentDisposition' );
    use ok( 'Mail::Make::Headers::ContentTransferEncoding' );
    use ok( 'Mail::Make::Headers::ContentType' );
    use ok( 'Mail::Make::Headers::Generic' );
    use ok( 'Mail::Make::Headers::MessageID' );
    use ok( 'Mail::Make::Headers::Subject' );
    use ok( 'Mail::Make::SMIME' );
    use ok( 'Mail::Make::Stream' );
    use ok( 'Mail::Make::Stream::Base64' );
    use ok( 'Mail::Make::Stream::QuotedPrint' );
};

done_testing();

__END__
