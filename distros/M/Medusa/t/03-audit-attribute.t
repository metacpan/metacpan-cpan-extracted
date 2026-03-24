#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

my $tempdir = tempdir(CLEANUP => 1);
my $logfile = File::Spec->catfile($tempdir, 'audit_test.log');

# Create a mock logger that captures messages
{
    package MockAuditLogger;
    our @MESSAGES;
    
    sub new {
        my $class = shift;
        @MESSAGES = ();
        return bless {}, $class;
    }
    
    sub debug {
        my ($self, $msg) = @_;
        push @MESSAGES, $msg;
    }
    
    sub info { shift->debug(@_) }
    sub error { shift->debug(@_) }
}

# Set up Medusa with mock logger before defining audited subs
BEGIN {
    require Medusa;
    $Medusa::LOG{LOG} = MockAuditLogger->new();
}

{
    package TestAudit;
    use Medusa;
    
    sub audited_sub :Audit {
        my ($self, $arg1, $arg2) = @_;
        return ($arg1 + $arg2, $arg1 * $arg2);
    }
    
    sub scalar_return :Audit {
        my ($self, $value) = @_;
        return $value * 2;
    }
    
    sub no_args :Audit {
        return 42;
    }
}

# Test: audited subroutine returns correct values in list context
{
    my @result = TestAudit->audited_sub(3, 4);
    is_deeply(\@result, [7, 12], 'audited sub returns correct list values');
}

=pod
# Test: audited subroutine returns correct value in scalar context
{
    my $result = TestAudit->scalar_return(5);
    is($result, 10, 'audited sub returns correct scalar value');
}

# Test: audited subroutine with no args works
{
    my $result = TestAudit->no_args();
    is($result, 42, 'audited sub with no args returns correctly');
}

# Test: logger captured call and return messages
{
    my $has_call = grep { /audited_sub called/ } @MockAuditLogger::MESSAGES;
    my $has_return = grep { /audited_sub returned/ } @MockAuditLogger::MESSAGES;
    
    ok($has_call, 'logger captured call message');
    ok($has_return, 'logger captured return message');
}
=cut
done_testing();
