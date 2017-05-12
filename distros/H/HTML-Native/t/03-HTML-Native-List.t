#!perl -T

use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
    use_ok ( "HTML::Native" );
    use_ok ( "HTML::Native::List" );
}

# Implicit construction

{
  my $elem = HTML::Native->new (
    div => { class => "welcome" },
    [ img => { src => "logo.png" } ],
    "Hello world!",
  );
  my $list = \@$elem;
  is_deeply ( \@$list, \@$elem );
  isa_ok ( $list, "HTML::Native::List" );
  isa_ok ( $list->[0], "HTML::Native" );
  is ( $list->[0], "<img src=\"logo.png\" />" );
  is ( $list->[1], "Hello world!" );
  is ( $list, "<img src=\"logo.png\" />Hello world!" );
}

# Explicit construction

{
  my $list = HTML::Native::List->new (
    [ img => { src => "logo.png" } ],
    "Hello world!",
  );
  isa_ok ( $list, "HTML::Native::List" );
  isa_ok ( $list->[0], "HTML::Native" );
  is ( $list->[0], "<img src=\"logo.png\" />" );
  is ( $list->[1], "Hello world!" );
  is ( $list, "<img src=\"logo.png\" />Hello world!" );
}

# FETCH()

{
  my $list = HTML::Native::List->new (
    [ h1 => "Welcome" ],
    [ img => { src => "logo.png" } ],
    "Hello world!",
  );
  isa_ok ( $list->[1], "HTML::Native" );
  is ( $list->[1], "<img src=\"logo.png\" />" );
}

# STORE()

{
  my $list = HTML::Native::List->new (
    [ h1 => "Welcome" ],
    [ img => { src => "logo.png" } ],
    "Hello world!",
  );
  is ( $list->[2], "Hello world!" );
  $list->[2] = "Byebye world!";
  is ( $list->[2], "Byebye world!" );
  $list->[2] = [ p => "Hi" ];
  isa_ok ( $list->[2], "HTML::Native" );
  is ( $list->[2], "<p>Hi</p>" );
}

# FETCHSIZE()

{
  my $list = HTML::Native::List->new (
    [ h1 => "Welcome" ],
    [ img => { src => "logo.png" } ],
    "Hello world!",
  );
  is ( @$list, 3 );
  pop @$list;
  is ( @$list, 2 );
}

# STORESIZE() / EXTEND()

{
  my $list = HTML::Native::List->new (
    [ h1 => "Welcome" ],
    [ img => { src => "logo.png" } ],
    "Hello world!",
  );
  @$list = ( "All gone" );
  is ( @$list, 1 );
  is ( $list, "All gone" );
  $#$list = ( 3 - 1 );
  is ( @$list, 3 );
}

# EXISTS()

{
  my $list = HTML::Native::List->new (
    [ h1 => "Welcome" ],
    undef,
    "Hello world!",
  );
  ok ( exists $list->[0] );
  ok ( exists $list->[1] );
  ok ( ! defined $list->[1] );
  ok ( exists $list->[2] );
  ok ( ! exists $list->[3] );
  $list->[7] = undef;
  ok ( ! exists $list->[6] );
  ok ( exists $list->[7] );
  ok ( ! exists $list->[8] );
}

# DELETE()

{
  my $list = HTML::Native::List->new (
    [ h1 => "Welcome" ],
    [ img => { src => "logo.png" } ],
    "Hello world!",
  );
  is ( @$list, 3 );
  is ( delete $list->[1], "<img src=\"logo.png\" />" );
  ok ( ! exists $list->[1] );
  is ( @$list, 3 );
  ok ( delete $list->[2], "Hello world! ");
  is ( @$list, 1 );
}

# CLEAR()

{
  my $list = HTML::Native::List->new (
    [ h1 => "Welcome" ],
    [ img => { src => "logo.png" } ],
    "Hello world!",
  );
  is ( @$list, 3 );
  @$list = ();
  is ( @$list, 0 );
  is ( $list, "" );
}

# PUSH()

{
  my $list = HTML::Native::List->new (
    [ h1 => "Welcome" ],
    "Hello world!",
  );
  is ( @$list, 2 );
  is ( ( push @$list, [ img => { src => "logo.png" } ] ), 3 );
  is ( @$list, 3 );
  isa_ok ( $list->[2], "HTML::Native" );
  is ( $list, "<h1>Welcome</h1>Hello world!<img src=\"logo.png\" />" );
}

# POP()

{
  my $list = HTML::Native::List->new (
    [ h1 => "Welcome" ],
    [ img => { src => "logo.png" } ],
    "Hello world!",
  );
  is ( @$list, 3 );
  ok ( pop @$list, "Hello world!" );
  is ( @$list, 2 );
  is ( $list, "<h1>Welcome</h1><img src=\"logo.png\" />" );
}

# SHIFT()

{
  my $list = HTML::Native::List->new (
    [ h1 => "Welcome" ],
    [ img => { src => "logo.png" } ],
    "Hello world!",
  );
  is ( @$list, 3 );
  ok ( shift @$list, "<h1>Welcome</h1>" );
  is ( @$list, 2 );
  is ( $list, "<img src=\"logo.png\" />Hello world!" );
}

# UNSHIFT()

{
  my $list = HTML::Native::List->new (
    [ img => { src => "logo.png" } ],
    "Hello world!",
  );
  is ( @$list, 2 );
  is ( ( unshift @$list, [ h1 => "Welcome" ] ), 3 );
  is ( @$list, 3 );
  isa_ok ( $list->[0], "HTML::Native" );
  is ( $list, "<h1>Welcome</h1><img src=\"logo.png\" />Hello world!" );
}

# SPLICE()

{
  my $list = HTML::Native::List->new (
    [ h1 => "Welcome" ],
    [ img => { src => "logo.png" } ],
    "Hello world!",
  );
  is ( @$list, 3 );
  splice ( @$list, 1, 2, "Byebye", [ img => { src => "world.png" } ] );
  is ( @$list, 3 );
  isa_ok ( $list->[2], "HTML::Native" );
  is ( $list, "<h1>Welcome</h1>Byebye<img src=\"world.png\" />" );
}

# Undefined entries

{
  my $list = HTML::Native::List->new ( "Hello", undef, " world" );
  is ( @$list, 3 );
  ok ( ! defined $list->[1] );
  is ( $list, "Hello world" );
}

# Dynamic generation (unblessed)

{
  my $msg = "Hello world!";
  my $list = HTML::Native::List->new (
    [ h1 => "Welcome" ],
    sub { return "\n", [ p => $msg ], "\n" },
    [ img => { src => "logo.png" } ],
  );
  isa_ok ( $list->[1], "CODE" );
  is ( $list,
       "<h1>Welcome</h1>\n<p>Hello world!</p>\n<img src=\"logo.png\" />" );
  $msg = "Byebye world!";
  isa_ok ( $list->[1], "CODE" );
  is ( $list,
       "<h1>Welcome</h1>\n<p>Byebye world!</p>\n<img src=\"logo.png\" />" );
}

# Dynamic generation (blessed)

{
  my $dyn = HTML::Native::List->new ( "\n", [ hr => ], "\n" );
  my $list = HTML::Native::List->new (
    [ h1 => "Welcome" ],
    "Hello world",
    sub { return $dyn; },
    [ img => { src => "logo.png" } ],
  );
  isa_ok ( $list->[2], "CODE" );
  is ( $list, "<h1>Welcome</h1>Hello world\n<hr />\n<img src=\"logo.png\" />" );
  $dyn = HTML::Native::List->new();
  is ( $list, "<h1>Welcome</h1>Hello world<img src=\"logo.png\" />" );
}

done_testing();
