{
    package Object;

    sub new { bless { a => 1 }, __PACKAGE__ }
}

{
    package Overload;

    use overload
        '""' => sub {
            "Bleh"
        };

    sub new { bless { b => 2 }, __PACKAGE__ }
}

my $scalar = \"a";
my $ref = \$scalar;
my $code = sub { 1 };
my $rx = qr/abc/;
my $obj = Object->new;
my $ovl = Overload->new;

$DB::single = 1;

1; # to avoid the program terminating
