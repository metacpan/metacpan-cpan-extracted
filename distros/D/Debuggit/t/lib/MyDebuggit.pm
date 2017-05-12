# for use with t/policy.t
package MyDebuggit;

use Debuggit ();

my $cur_formatter = $Debuggit::formatter;
$Debuggit::formatter = sub { return 'XX: ' . $cur_formatter->(@_) };

sub import
{
    my $class = shift;
    Debuggit->import(PolicyModule => 1, @_);
}


1;
