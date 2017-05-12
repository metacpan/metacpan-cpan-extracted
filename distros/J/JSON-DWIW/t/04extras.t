#!/usr/bin/env perl

# Creation date: 2007-03-20 18:01:54
# Authors: don

use strict;
use warnings;
use Test;

# main
{
    BEGIN { plan tests => 25 }

    use JSON::DWIW;

    # bare keys (called as class method)
    my $json_str = '{var1:true,var2:false,var3:null}';
    my $data = JSON::DWIW->from_json($json_str);
    
    ok(ref($data) eq 'HASH');
    ok(ref($data) eq 'HASH' and $data->{var1});
    ok(ref($data) eq 'HASH' and not $data->{var2});
    ok(ref($data) eq 'HASH' and exists($data->{var3}) and not defined($data->{var3}));

    $json_str = '{$var1:true,var2:false,var3:null}';
    $data = JSON::DWIW->from_json($json_str);
    ok(ref($data) eq 'HASH' and $data->{'$var1'} and not $data->{var2}
       and exists($data->{var3}) and not defined($data->{var3}));
    
    $json_str = '{_var1_:true,var2:false,var3:null}';
    $data = JSON::DWIW->from_json($json_str);
    ok(ref($data) eq 'HASH' and $data->{'_var1_'} and not $data->{var2}
       and exists($data->{var3}) and not defined($data->{var3}));

    # call as subroutine (possible imported)
    $json_str = '{var1:true,var2:false,var3:null}';
    $data = JSON::DWIW::from_json($json_str);
    ok(ref($data) eq 'HASH');
    ok(ref($data) eq 'HASH' and $data->{var1});
    ok(ref($data) eq 'HASH' and not $data->{var2});
    ok(ref($data) eq 'HASH' and exists($data->{var3}) and not defined($data->{var3}));

    # call as instance method
    my $json_obj = JSON::DWIW->new;
    $json_str = '{var1:true,var2:false,var3:null}';
    $data = $json_obj->from_json($json_str);
    ok(ref($data) eq 'HASH');
    ok(ref($data) eq 'HASH' and $data->{var1});
    ok(ref($data) eq 'HASH' and not $data->{var2});
    ok(ref($data) eq 'HASH' and exists($data->{var3}) and not defined($data->{var3}));

    # extra commas
    $json_str = '{,"var1":true,,"var2":false,"var3":null,, ,}';
    $data = JSON::DWIW->from_json($json_str);
    ok(ref($data) eq 'HASH');
    ok(ref($data) eq 'HASH' and $data->{var1});
    ok(ref($data) eq 'HASH' and not $data->{var2});
    ok(ref($data) eq 'HASH' and exists($data->{var3}) and not defined($data->{var3}));

    
    # C++ style comments
    $json_str = '{"test_empty_hash":{} ' . "\n" . '//,"test_empty_array":[] ' . "\n" . '}';
    $data = JSON::DWIW->from_json($json_str);
    ok(ref($data) eq 'HASH' and scalar(keys(%$data)) == 1
       and ref($data->{test_empty_hash}) eq 'HASH'
       and scalar(keys %{$data->{test_empty_hash}}) == 0);

    # encoding bare keys
    $json_obj = JSON::DWIW->new({ bare_keys => 1 });
    $data = { var1 => "val2" };
    $json_str = $json_obj->to_json($data);
    ok($json_str eq '{var1:"val2"}');
    $json_str = JSON::DWIW->to_json($data, { bare_keys => 1 });
    ok($json_str eq '{var1:"val2"}');
    $json_str = JSON::DWIW::to_json($data, { bare_keys => 1 });
    ok($json_str eq '{var1:"val2"}');

    $data = { var => "stuff\xe9stuff" };
    undef $json_str;
    {
        local $SIG{__WARN__} = sub { };
        $json_str = JSON::DWIW->to_json($data, { bad_char_policy => 'convert',
                                                 escape_multi_byte => 1,
                                               });
    }
    ok($json_str eq '{"var":"stuff\u00e9stuff"}');

    $data = { var => "stuff\xe9stuff" };
    undef $json_str;
    {
        local $SIG{__WARN__} = sub { };
        $json_str = JSON::DWIW->to_json($data, { bad_char_policy => 'convert',
                                                 ascii => 1,
                                               });
    }
    ok($json_str eq '{"var":"stuff\u00e9stuff"}');

    # make sure no elements are left out when pretty-printing
    # (bug in version 0.12)
    $data = { var1 => 'val1', var2 => { stuff1 => 'content2', stuff2 => 1 }, var3 => 'val3',
              var4 => [ 'test1', 'test2', 'test3' ]};
    $json_str = JSON::DWIW->to_json($data, { pretty => 1 });
    $data = JSON::DWIW->from_json($json_str);
    ok(scalar(@{ $data->{var4} }) == 3 and $data->{var2}{stuff1} and $data->{var2}{stuff2}
       and scalar(keys(%$data)) == 4);
                                   
}

exit 0;

###############################################################################
# Subroutines

