#!perl -T

use Test::More tests => 688;

use Log::Fine;
use Log::Fine::Handle::String;
use Log::Fine::Levels::Java qw( :macros :masks );

# Mask to Level mapping
my $ltov = Log::Fine::Levels::Java->LVLTOVAL_MAP;
my $vtol = Log::Fine::Levels::Java->VALTOLVL_MAP;
my $mtov = Log::Fine::Levels::Java->MASK_MAP;

# Set message
my $msg = "Stop by this disaster town, we put our eyes to the sun and say 'Hello!'";

{

        my $levels = Log::Fine::Levels::Java->new();

        # Levels should be a *::Java object
        isa_ok($levels, "Log::Fine::Levels::Java");

        # Validate methods
        can_ok($levels, $_) foreach (qw/ new bitmaskAll levelToValue maskToValue valueToLevel /);

        # Build mask to level map
        my @levels    = $levels->logLevels();
        my @masks     = $levels->logMasks();
        my $lvlCount  = scalar @levels;
        my $maskCount = scalar @masks;

        ok($lvlCount > 0);
        ok($maskCount > 0);

        # Make sure levels are in ascending order by val;
        my $val = 0;
        foreach my $level (@levels) {
                next if $ltov->{$level} == 0;
                ok($ltov->{$level} > $val);
                $val = $ltov->{$level};
        }

        # Make sure masks are ascending order by val
        $val = 0;
        foreach my $mask (@masks) {
                next if $mtov->{$mask} == 0;
                ok($mtov->{$mask} > $val);
                $val = $mtov->{$mask};
        }

        # Variable for holding bitmask
        my $bitmask = 0;

        for (my $i = 0; $i < $lvlCount; $i++) {
                ok($i == $levels->levelToValue($levels[$i]));
                ok(&{ $levels[$i] } eq $i);
                ok(&{ $masks[$i] } eq $levels->maskToValue($masks[$i]));

                $bitmask |= $levels->maskToValue($masks[$i]);
        }

        ok($bitmask == $levels->bitmaskAll());
        ok($levels->MASK_MAP($_) =~ /\d/) foreach (@masks);

        # Initialize some Log::Fine objects
        my $log    = Log::Fine->new();
        my $handle = Log::Fine::Handle::String->new();

        # Validate handle types
        isa_ok($handle, "Log::Fine::Handle");

        # Resort levels and masks
        @levels    = sort keys %{$ltov};
        @masks     = sort keys %{$mtov};
        $lvlCount  = scalar @levels;
        $maskCount = scalar @masks;

        ok($lvlCount == $maskCount);

        for (my $i = 0; $i < $lvlCount; $i++) {
                $mtolv->{ $mtov->{ $masks[$i] } } = $ltov->{ $levels[$i] };
        }

        # Validate default attributes
        ok($handle->{mask} == $log->levelMap()->bitmaskAll());

        # Build array of mask values
        my @mv;
        push @mv, $mtov->{$_} foreach (@masks);

        # Clear bitmask
        $handle->{mask} = 0;

        # Now recursive test isLoggable() with sorted values of masks
        testmask(0, sort { $a <=> $b } @mv);

}

# --------------------------------------------------------------------

sub testmask
{

        my $bitmask = shift;
        my @masks   = @_;

        # Return if there are no more elements to test
        return unless scalar @masks;

        # Shift topmost mask off
        my $lvlmask = shift @masks;

        # Validate lvlmask
        ok($lvlmask =~ /\d/);

        # Determine lvl and create a new handle
        my $lvl = $vtol->{ $mtolv->{$lvlmask} };
        my $handle = Log::Fine::Handle::String->new(mask => $bitmask);

        # Current level should not be set so do negative test
        isa_ok($handle, "Log::Fine::Handle");
        can_ok($handle, "isLoggable");

        ok(!$handle->isLoggable(eval "$lvl"));

        # Recurse downward again
        testmask($handle->{mask}, @masks);

        # Now we do positive testing
        $handle->{mask} |= $lvlmask;

        # Do a positive test
        ok($handle->isLoggable(eval "$lvl"));

        # Now that the bitmask has been set iterate downward again
        testmask($handle->{mask}, @masks);

}          # testmask()
