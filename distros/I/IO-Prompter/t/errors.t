#use 5.010;
use warnings;
use Test::More 'no_plan';

use IO::Prompter;
 
eval { my $val = prompt "Enter line 1", -timeout };
like $@, qr/prompt\(\): Missing value for -timeout \(expected number of seconds\)/
    => '-timeout missing value exception';

eval { my $val = prompt "Enter line 1", -timeout=>'yes' };
like $@, qr/prompt\(\): Invalid value for -timeout \(expected number of seconds\)/
    => '-timeout invalid value exception';


{
    my $warned;
    local $SIG{__WARN__} = sub {
        my ($warning) = @_;
        like $warning, qr/\AUseless use of prompt\(\) in void context/
            => 'void context warning';
        $warned = 1;
    };

    my $input = 'text';
    open my $fh, '<', \$input or die $!;
    prompt "Enter line 1", -in=>$fh;
    fail 'void context warning' if !$warned;
}


{
    no warnings 'void';
    my $warned;
    local $SIG{__WARN__} = sub {
        $warned = 1;
    };

    my $input = 'text';
    open my $fh, '<', \$input or die $!;
    prompt "Enter line 1", -in=>$fh;
    ok !$warned => 'muffled void context warning';
}

{
    my $warned;
    local $SIG{__WARN__} = sub {
        $warned = 1;
    };

    my $input = 'text';
    open my $fh, '<', \$input or die $!;
    prompt "Enter line 1", -in=>$fh, -void;
    ok !$warned => 'turned off void context warning with -void';
}

{
    my $warned;
    local $SIG{__WARN__} = sub {
        my ($warning) = @_;
        like $warning, qr/\Aprompt\(\): Unknown option -zen ignored/
            => 'Unknown option warning';
        $warned = 1;
    };

    my $input = 'text';
    open my $fh, '<', \$input or die $!;
    my $result = prompt "Enter line 1", -in=>$fh, -zen;
    fail 'unknown option warning' if !$warned;
}

{
    my $warned;
    local $SIG{__WARN__} = sub {
        $warned = 1;
    };

    my $input = 'text';
    open my $fh, '<', \$input;
    no warnings 'misc';
    my $result = prompt "Enter line 1", -in=>$fh, -foobar;
    ok !$warned => 'muffled unknown option warning';
}

