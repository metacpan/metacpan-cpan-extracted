#!perl -T

use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
    use_ok ( "HTML::Native" );
    use_ok ( "HTML::Native::JavaScript" );
}

# new() without inline code

{
  my $js = HTML::Native::JavaScript->new ( { src => "script.js" } );
  isa_ok ( $js, "HTML::Native::JavaScript" );
  is ( $$js, "script" );
  is ( $js->{type}, "text/javascript" );
  is ( $js, "<script src=\"script.js\" type=\"text/javascript\"></script>" );
}

# new() with inline code string

{
  my $raw = "\$( function () { alert ( \"hello\" ) } )";
  my $js = HTML::Native::JavaScript->new ( $raw );
  isa_ok ( $js, "HTML::Native::JavaScript" );
  isa_ok ( \$raw, "SCALAR" );
  is ( $js,
       "<script type=\"text/javascript\">//<![CDATA[\n".
       "\$( function () { alert ( \"hello\" ) } )\n".
       "//]]></script>" );
  $raw .= "\n".$raw;
  is ( $js,
       "<script type=\"text/javascript\">//<![CDATA[\n".
       "\$( function () { alert ( \"hello\" ) } )\n".
       "//]]></script>" );
}

# new() with inline code reference

{
  my $raw = "\$( function () { alert ( \"hello\" ) } )";
  my $js = HTML::Native::JavaScript->new ( \$raw );
  isa_ok ( $js, "HTML::Native::JavaScript" );
  isa_ok ( \$raw, "SCALAR" );
  is ( $js,
       "<script type=\"text/javascript\">//<![CDATA[\n".
       "\$( function () { alert ( \"hello\" ) } )\n".
       "//]]></script>" );
  $raw .= "\n".$raw;
  is ( $js,
       "<script type=\"text/javascript\">//<![CDATA[\n".
       "\$( function () { alert ( \"hello\" ) } )\n".
       "\$( function () { alert ( \"hello\" ) } )\n".
       "//]]></script>" );
}

# CDATA end marker detection

{
  my $js = HTML::Native::JavaScript->new ( "oh ]]> dear" );
  isa_ok ( $js, "HTML::Native::JavaScript" );
  dies_ok { $js.""; };
}

done_testing();
