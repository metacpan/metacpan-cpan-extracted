use warnings;
use strict;

use Test::More;

use Data::Dumper;
use Dist::Mgr qw(:private);
use JSON;

use lib 't/lib';
use Helper qw(:all);

my @valid_keys = qw(
    cpan_id
    cpan_pw
);

# bad params
{
    is eval {config(); 1}, undef, "config() requires args param ok";
    is eval {config([]); 1}, undef, "config() requires args param as href ok";
}

# defaults and default file
{
    my $file = config_file();

    remove($file);

    my %args;

    is -e $file, undef, "config file $file doesn't exist ok";

    my $ret = config(\%args);

    is keys %args, 0, "with default config file, no keys are added to args";
    is keys %{ $ret }, 0, "with default config file, no keys in returned href";

    is -e $file, 1, "default config file $file created upon first config() call ok";

    my $data = get($file);

    is keys %$data, scalar @valid_keys, "key count in config file ok";

    for (@valid_keys) {
        is exists $data->{$_}, 1, "key $_ exists in conf file ok";
    }

    # individual key default values

    is $data->{cpan_id}, '', "cpan_id is empty string ok";
    is $data->{cpan_pw}, '', "cpan_pw is empty string ok";

    $data->{cpan_id} = 'steveb';
    $data->{cpan_pw} = 'testing';

    # write new file and check for updated %args

    put($file, $data);

    $ret = config(\%args);

    is keys %args, 2, "with updated config file, keys are added to args";
    is keys %{ $ret }, 2, "with updated config file, keys added in returned href";

    is $args{cpan_id}, 'steveb', "updated cpan_id ok";
    is $args{cpan_pw}, 'testing', "updated cpan_pw ok";

    remove($file);
}

# alternate file
{
    my $file = 't/data/work/dist-mgr.json';

    remove($file);

    my %args;

    is -e $file, undef, "config file $file doesn't exist ok";

    my $ret = config(\%args, $file);

    is keys %args, 0, "with default config file, no keys are added to args";
    is keys %{ $ret }, 0, "with default config file, no keys in returned href";

    is -e $file, 1, "config file $file created upon first config() call ok";

    my $data = get($file);

    is keys %$data, scalar @valid_keys, "key count in config file ok";

    for (@valid_keys) {
        is exists $data->{$_}, 1, "key $_ exists in conf file ok";
    }

    # individual key default values

    is $data->{cpan_id}, '', "cpan_id is empty string ok";
    is $data->{cpan_pw}, '', "cpan_pw is empty string ok";

    $data->{cpan_id} = 'steveb';
    $data->{cpan_pw} = 'testing';

    # write new file and check for updated %args

    put($file, $data);

    $ret = config(\%args, $file);

    is keys %args, 2, "with updated config file, keys are added to args";
    is keys %{ $ret }, 2, "with updated config file, keys added in returned href";

    is $args{cpan_id}, 'steveb', "updated cpan_id ok";
    is $args{cpan_pw}, 'testing', "updated cpan_pw ok";

    remove($file);
}

done_testing();

sub get {
    my ($conf_file) = @_;
    {
        local $/;
        open my $fh, '<', $conf_file or die "can't open $conf_file: $!";
        my $json = <$fh>;
        my $perl = decode_json($json);
        return $perl;
    }
}
sub put {
    my ($conf_file, $data) = @_;
    {
        local $/;
        open my $fh, '>', $conf_file or die "can't open $conf_file: $!";
        my $jobj = JSON->new;

        print $fh $jobj->pretty->encode($data);
    }
}
sub remove {
    my ($conf_file) = @_;

    if (-e $conf_file) {
        unlink $conf_file or die "Can't remove config file $conf_file: $!";
        is -e $conf_file, undef, "Removed config file $conf_file ok";
    }

    is -e $conf_file, undef, "(unlink) config file $conf_file doesn't exist ok";
}

