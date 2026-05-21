# -*- perl -*-
BEGIN
{
    use strict;
    use lib './lib';
    use Test::More qw( no_plan );
};

# To build the list of modules:
# find ./lib -type f -name "*.pm" -print | xargs perl -lE 'my @f=sort(@ARGV); for(@f) { s,./lib/,,; s,\.pm$,,; s,/,::,g; substr( $_, 0, 0, q{use_ok( ''} ); $_ .= q{'' );}; say $_; }'
BEGIN
{
    use_ok( 'MM::Const' );
    use_ok( 'MM::Table' );
    use_ok( 'Mail::Make' );
    use_ok( 'Mail::Make::Body' );
    use_ok( 'Mail::Make::Body::File' );
    use_ok( 'Mail::Make::Body::InCore' );
    use_ok( 'Mail::Make::Entity' );
    use_ok( 'Mail::Make::Exception' );
    use_ok( 'Mail::Make::GPG' );
    use_ok( 'Mail::Make::Headers' );
    use_ok( 'Mail::Make::Headers::ContentDisposition' );
    use_ok( 'Mail::Make::Headers::ContentTransferEncoding' );
    use_ok( 'Mail::Make::Headers::ContentType' );
    use_ok( 'Mail::Make::Headers::Generic' );
    use_ok( 'Mail::Make::Headers::MessageID' );
    use_ok( 'Mail::Make::Headers::Subject' );
    use_ok( 'Mail::Make::SMIME' );
    use_ok( 'Mail::Make::Stream' );
    use_ok( 'Mail::Make::Stream::Base64' );
    use_ok( 'Mail::Make::Stream::QuotedPrint' );
};

done_testing();

__END__
