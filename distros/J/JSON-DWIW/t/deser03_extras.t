#!/usr/bin/env perl

# Creation date: 2007-03-20 18:01:54
# Authors: don

use strict;
use warnings;
use Test;

# main
{
    use JSON::DWIW;

    if (JSON::DWIW->has_deserialize) {
        plan tests => 21;
    }
    else {
        plan tests => 1;

        print "# deserialize not implemented on this platform\n";
        skip("Skipping on this platform", 0); # skipping on this platform
        exit 0;
    }


    my $json_str;
    my $data;

    # bare keys
    $json_str = '{var1:true,var2:false,var3:null}';
    $data = JSON::DWIW::deserialize($json_str);
    ok(ref($data) eq 'HASH');
    ok(ref($data) eq 'HASH' and $data->{var1});
    ok(ref($data) eq 'HASH' and not $data->{var2});
    ok(ref($data) eq 'HASH' and exists($data->{var3}) and not defined($data->{var3}));
    
    $json_str = '{$var1:true,var2:false,var3:null}';
    $data = JSON::DWIW::deserialize($json_str);
    ok(ref($data) eq 'HASH' and $data->{'$var1'} and not $data->{var2}
       and exists($data->{var3}) and not defined($data->{var3}));
    
    $json_str = '{_var1_:true,var2:false,var3:null}';
    $data = JSON::DWIW::deserialize($json_str);
    ok(ref($data) eq 'HASH' and $data->{'_var1_'} and not $data->{var2}
       and exists($data->{var3}) and not defined($data->{var3}));

    # extra commas
    $json_str = '{,"var1":true,,"var2":false,"var3":null,, ,}';
    $data = JSON::DWIW::deserialize($json_str);
    ok(ref($data) eq 'HASH');
    ok(ref($data) eq 'HASH' and $data->{var1});
    ok(ref($data) eq 'HASH' and not $data->{var2});
    ok(ref($data) eq 'HASH' and exists($data->{var3}) and not defined($data->{var3}));

    # C style comments
    $json_str = '{"test_empty_hash":{} /*,"test_empty_array":[] */}';
    $data = JSON::DWIW::deserialize($json_str);
    ok(ref($data) eq 'HASH' and scalar(keys(%$data)) == 1
       and ref($data->{test_empty_hash}) eq 'HASH'
       and scalar(keys %{$data->{test_empty_hash}}) == 0);

    
    # C++ style comments
    $json_str = '{"test_empty_hash":{} ' . "\n" . '//,"test_empty_array":[] ' . "\n" . '}';
    $data = JSON::DWIW::deserialize($json_str);
    ok(ref($data) eq 'HASH' and scalar(keys(%$data)) == 1
       and ref($data->{test_empty_hash}) eq 'HASH'
       and scalar(keys %{$data->{test_empty_hash}}) == 0);

    # Perl, shell, etc., style comments
    $json_str = '{"test_empty_hash":{} ' . "\n" . '#,"test_empty_array":[] ' . "\n" . '}';
    $data = JSON::DWIW::deserialize($json_str);
    ok(ref($data) eq 'HASH' and scalar(keys(%$data)) == 1
       and ref($data->{test_empty_hash}) eq 'HASH'
       and scalar(keys %{$data->{test_empty_hash}}) == 0);

    # make sure no elements are left out when pretty-printing
    # (bug in version 0.12)
    $data = { var1 => 'val1', var2 => { stuff1 => 'content2', stuff2 => 1 }, var3 => 'val3',
              var4 => [ 'test1', 'test2', 'test3' ]};
    $json_str = JSON::DWIW->to_json($data, { pretty => 1 });
    $data = JSON::DWIW::deserialize($json_str);
    ok(scalar(@{ $data->{var4} }) == 3 and $data->{var2}{stuff1} and $data->{var2}{stuff2}
       and scalar(keys(%$data)) == 4);

    $json_str = 'true';
    $data = JSON::DWIW::deserialize($json_str);
    ok(not ref($data) and $data);

    $json_str = 'false';
    $data = JSON::DWIW::deserialize($json_str);
    ok(not ref($data) and not $data);

    $json_str = 'null';
    $data = JSON::DWIW::deserialize($json_str);
    ok(not defined($data) and not defined(JSON::DWIW->get_error_string));

    $json_str = '567';
    $data = JSON::DWIW::deserialize($json_str);
    ok($data == 567);


    # normal case
    $json_str = qq{{"var":"\xc3\xa9"}};
    $data = JSON::DWIW::deserialize($json_str);
    printf "# ord = %#02x\n", ord($data->{var});
    ok($data and ord($data->{var}) == 0xe9);

    # needs converting case
    $json_str = qq{{"var":"\xe9"}};
    {
        local $SIG{__WARN__} = sub { };
        $data = JSON::DWIW::deserialize($json_str);
    }
    ok(not $data and defined(JSON::DWIW->get_error_string));
    
    # needs converting case -- do the conversion
    $json_str = qq{{"var":"\xe9"}};
    {
        local $SIG{__WARN__} = sub { };
        $data = JSON::DWIW::deserialize($json_str, { bad_char_policy => 'convert' });
    }
    ok($data and ord($data->{var}) == 0xe9);

    
    
                                   
}

exit 0;

###############################################################################
# Subroutines

