#########################

use Test::More tests => 1;

require_ok 'Encode::Mapper';

__END__

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

    use Data::Dump 'dump';                  # pretty data printing is below

    $Encode::Mapper::options{'ByForce'} = { qw ':others - silent errors' };

    package ByMethod;                       # import called at compile time
                                            # no warnings, 'silent' is true
    Encode::Mapper->options('complement' => [ 'X', 'Y' ], 'others' => 'X');
    use Encode::Mapper 'silent' => 299_792_458;

    package main;                           # import called at compile time
                                            # 'non-existent' may exist once
    print dump %Encode::Mapper::options;
    use Encode::Mapper ':others', ':silent', 'non-existent', 'one';

    # (
    #   "ByMethod",
    #   { complement => ["X", "Y"], others => "X", silent => 299_792_458 },
    #   "ByForce",
    #   { ":others" => "-", silent => "errors" },
    #   "main",
    #   { "non-existent" => "one", others => sub { "???" }, silent => 1 },
    # )
