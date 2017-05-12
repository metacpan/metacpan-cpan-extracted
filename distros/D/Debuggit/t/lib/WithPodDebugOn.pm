# for use with t/pod_coverage_with_debug.t
package WithPodDebugOn;

# not that you should be releasing anything with debugging on,
# but may as well make sure it doesn't cause a problem anyway
use Debuggit DEBUG => 3;


sub foo
{
}


1;


=pod

=head2 foo

=cut
