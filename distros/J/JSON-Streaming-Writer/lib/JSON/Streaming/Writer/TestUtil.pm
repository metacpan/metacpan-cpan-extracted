
package JSON::Streaming::Writer::TestUtil;

# Just some utility bits for the test scripts to use.

use strict;
use warnings;
use base qw(Exporter);
use JSON::Streaming::Writer;
use Symbol;

our @EXPORT = qw(test_jsonw test_jsonw_croak);

sub test_jsonw {
    my ($test_name, $correct_output, $code) = @_;

    my $fh = JSON::Streaming::Writer::TestUtil::FakeHandle->new();
    my $jsonw = JSON::Streaming::Writer->for_stream($fh);

    $code->($jsonw);

    my $actual_output = $fh->result;

    Test::More::is($correct_output, $actual_output, $test_name) if defined($correct_output);
}

sub test_jsonw_croak {
    my ($test_name, $code) = @_;

    eval {
        test_jsonw($test_name, undef, $code);
    };
    if ($@) {
        Test::More::pass($test_name);
    }
    else {
        Test::More::fail($test_name);
    }
}

package JSON::Streaming::Writer::TestUtil::FakeHandle;

sub new {
    my ($class) = @_;

    my $sym = Symbol::gensym();
    return tie(*$sym, __PACKAGE__);
}

sub TIEHANDLE {
    my ($class) = @_;

    my $buf = "";
    my $ret = \$buf;
    my $self = bless $ret, $class;
    return $ret;
}

sub print {
    ${(shift)} .= join('', @_);
}

sub result {
    return ${$_[0]};
}

1;

