#!perl -T

use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok ( "HTML::Native" );
    use_ok ( "HTML::Native::Attributes" );
}

# Implicit construction

{
  my $elem = HTML::Native->new ( a => { href => "/home" }, "Home" );
  my $attrs = \%$elem;
  is_deeply ( \%$attrs, \%$elem );
  isa_ok ( $attrs, "HTML::Native::Attributes" );
  isa_ok ( $attrs->{href}, "HTML::Native::Attribute" );
  is ( $elem->{href}, "/home" );
  is ( $attrs->{href}, "/home" );
  is ( $attrs, " href=\"/home\"" );
}

# Explicit construction

{
  my $attrs = HTML::Native::Attributes->new ( { src => "logo.png" } );
  isa_ok ( $attrs, "HTML::Native::Attributes" );
  isa_ok ( $attrs->{src}, "HTML::Native::Attribute" );
  is ( $attrs->{src}, "logo.png" );
  is ( $attrs, " src=\"logo.png\"" );
}

# FETCH()

{
  my $attrs = HTML::Native::Attributes->new ( { src => "logo.png" } );
  isa_ok ( $attrs->{src}, "HTML::Native::Attribute" );
  is ( $attrs->{src}, "logo.png" );
}

# STORE()

{
  my $attrs = HTML::Native::Attributes->new ( { src => "logo.png" } );
  $attrs->{src} = "error.png";
  isa_ok ( $attrs->{src}, "HTML::Native::Attribute" );
  is ( $attrs->{src}, "error.png" );
  $attrs->{alt} = "Error!";
  isa_ok ( $attrs->{alt}, "HTML::Native::Attribute" );
  is ( $attrs->{alt}, "Error!" );
  $attrs->{class}->{error} = 1;
  is ( $attrs->{class}, "error" );
  is ( $attrs, " alt=\"Error!\" class=\"error\" src=\"error.png\"" );
}

# DELETE()

{
  my $attrs = HTML::Native::Attributes->new ( { src => "logo.png",
						alt => "Logo" } );
  is ( $attrs, " alt=\"Logo\" src=\"logo.png\"" );
  is ( delete $attrs->{alt}, "Logo" );
  is ( $attrs, " src=\"logo.png\"" );
}

# CLEAR()

{
  my $attrs = HTML::Native::Attributes->new ( { src => "logo.png",
						alt => "Logo" } );
  is ( $attrs, " alt=\"Logo\" src=\"logo.png\"" );
  %$attrs = ();
  isa_ok ( $attrs, "HTML::Native::Attributes" );
  is ( $attrs, "" );
}

# EXISTS()

{
  my $attrs = HTML::Native::Attributes->new ( { src => "logo.png",
						alt => "Logo" } );
  ok ( exists $attrs->{src} );
  ok ( exists $attrs->{alt} );
  ok ( ! exists $attrs->{class} );
  ok ( ! exists $attrs->{class} ); # Repeat to check no auto-vivification
  $attrs->{class} = undef;
  ok ( exists $attrs->{class} );
  isa_ok ( $attrs->{class}, "HTML::Native::Attribute" );
  $attrs->{class} = "error";
  ok ( exists $attrs->{class} );
  isa_ok ( $attrs->{class}, "HTML::Native::Attribute" );
  delete $attrs->{alt};
  ok ( ! exists $attrs->{alt} );
}

# FIRSTKEY() / NEXTKEY()

{
  my $attrs = HTML::Native::Attributes->new ( { src => "logo.png",
						alt => "Logo" } );
  is_deeply ( [ sort keys %$attrs ], [ "alt", "src" ] );
  is_deeply ( [ sort values %$attrs ], [ "Logo", "logo.png" ] );
  while ( ( my $key, my $value ) = each %$attrs ) {
    $value =~ s/logo/error/i;
    $attrs->{$key} = $value;
  }
  is ( $attrs, " alt=\"error\" src=\"error.png\"" );
}

# SCALAR()

{
  my $attrs = HTML::Native::Attributes->new ( { src => "logo.png",
						alt => "Logo" } );
  ok ( scalar %$attrs );
  delete $attrs->{alt};
  ok ( scalar %$attrs );
  delete $attrs->{src};
  ok ( ! scalar %$attrs );
}

done_testing();
