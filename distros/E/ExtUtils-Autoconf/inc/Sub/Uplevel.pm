#line 1
package Sub::Uplevel;

use 5.006;

use strict;
use vars qw($VERSION @ISA @EXPORT);
$VERSION = 0.09;

# We have to do this so the CORE::GLOBAL versions override the builtins
_setup_CORE_GLOBAL();

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(uplevel);

#line 73

our $Up_Frames = 0;
sub uplevel {
    my($num_frames, $func, @args) = @_;
    local $Up_Frames = $num_frames + $Up_Frames;

    return $func->(@args);
}


sub _setup_CORE_GLOBAL {
    no warnings 'redefine';

    *CORE::GLOBAL::caller = sub {
        my $height = $_[0] || 0;

#line 115

        $height++;  # up one to avoid this wrapper function.

        my $saw_uplevel = 0;
        # Yes, we need a C style for loop here since $height changes
        for( my $up = 1;  $up <= $height + 1;  $up++ ) {
            my @caller = CORE::caller($up);
            if( defined($caller[0]) and $caller[0] eq __PACKAGE__ ) {
                $height++;
                $height += $Up_Frames unless $saw_uplevel;
                $saw_uplevel = 1;
            }
        }
                

        return undef if $height < 0;
        my @caller = CORE::caller($height);

        if( wantarray ) {
            if( !@_ ) {
                @caller = @caller[0..2];
            }
            return @caller;
        }
        else {
            return $caller[0];
        }
    };

}


#line 213


1;
