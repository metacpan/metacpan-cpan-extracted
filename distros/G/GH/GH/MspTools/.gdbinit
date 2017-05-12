###############################################################################
# Electric Fence
#
# Debian's Electric Fence package provides efence as a shared library, which is
# very useful.
###############################################################################

define efence
        set environment EF_PROTECT_BELOW 0
        set environment LD_PRELOAD ./libefence.so.0.0
        echo Enabled Electric Fence\n
end
document efence
Enable memory allocation debugging through Electric Fence (efence(3)).
        See also nofence and underfence.
end


define underfence
        set environment EF_PROTECT_BELOW 1
        set environment LD_PRELOAD ./libefence.so.0.0
        echo Enabled Electric Fence for undeflow detection\n
end
document underfence
Enable memory allocation debugging for underflows through Electric Fence 
(efence(3)).
        See also nofence and underfence.
end


define nofence
        unset environment LD_PRELOAD
        echo Disabled Electric Fence\n
end
document nofence
Disable memory allocation debugging through Electric Fence (efence(3)).
end

set args -d -I../blib/arch -I../blib/lib -I/home/hartzell/atlantes/lib/perl5/5.6.0/i686-linux -I/home/hartzell/atlantes/lib/perl5/5.6.0 t/5.getmspsbulk.t

define  bb
   b msp_helpers.c:buildBulkMSPs
end

