# Copyrights 2011-2015 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package IOMux::Open;
use vars '$VERSION';
$VERSION = '1.00';


use Log::Report 'iomux';

my %modes =
  ( '-|'  => 'IOMux::Pipe::Read'
  , '|-'  => 'IOMux::Pipe::Write'
  , '|-|' => 'IOMux::IPC'
  , '|=|' => 'IOMux::IPC'
  , '>'   => 'IOMux::File::Write'
  , '>>'  => 'IOMux::File::Write'
  , '<'   => 'IOMux::File::Read'
  , tcp   => 'IOMux::Net::TCP'
  );

sub import(@)
{   my $class = shift;
    foreach my $mode (@_)
    {   my $impl = $modes{$mode}
            or error __x"unknown mode {mode} in use {pkg}"
              , mode => $mode, pkg => $class;
        eval "require $impl";
        panic $@ if $@;
    }
}
    

sub new($@)
{   my ($class, $mode) = (shift, shift);
    my $real  = $modes{$mode}
        or error __x"unknown mode '{mode}' to open() on mux", mode => $mode;

    $real->can('open')
        or error __x"package {pkg} for mode '{mode}' not required by {me}"
             , pkg => $real, mode => $mode, me => $class;

    $real->open($mode, @_);
}

#--------------

1;
