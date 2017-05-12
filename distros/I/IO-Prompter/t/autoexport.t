use Test::More;

use IO::Prompter { ask => [-yn1, -verbatim] };

{
    open my $in_fh, '<', \'y' or die;
    my $response = ask(-in=>$in_fh);
    is $response, 'y'   => 'Ask matched on single y';
    ok !ref($response)  => 'Verbatim';
}

{
    use IO::Prompter { ask => [-yn1] };
    open my $in_fh, '<', \'y' or die;
    my $response = ask(-in=>$in_fh);
    is $response, 'y'   => 'Ask matched on single y';
    ok ref($response)   => 'Not verbatim';
}

{
    open my $in_fh, '<', \'y' or die;
    my $response = ask(-in=>$in_fh);
    is $response, 'y'   => 'Ask matched on single y';
    ok !ref($response)  => 'Verbatim';
}

done_testing();
