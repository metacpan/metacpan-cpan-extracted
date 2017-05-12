# Device-BlinkStick

Control a BlinkStick (http://blinkstick.com/).

Aims to provide a similar set of functions as the python implementation,
but obviously in perl!

The command line script is called 'stick', rather than blinkstick, so that you can
have both installed on your system, as this perl version currently does not have
all the features of the python command line script.

## Installation

You may have issues with Device::USB, you may have to install this by hand.
Make sure you have libusb-dev installed (unix) and remove the line

        VERSION => '0.36',

From line 17 ot lib/Device/USB.pm - this is part of the Inline block and the source of build/install
problems. You may also get a message like

    Insecure dependency in chdir while running with -T switch at /home/kevin/perl5/perlbrew/perls/perl-5.20.1/lib/site_perl/5.20.1/Inline/C.pm line 868

We will have to ignore this and 'make install' anyway to get Device::USB installed and working

To get things working as a user you will need to grant permissions to USB

    echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"20a0\", ATTR{idProduct}==\"41e5\", MODE:=\"0666\"" | sudo tee /etc/udev/rules.d/85-blinkstick.rules

This may also require a reboot, though a 'service udev restart' may also do the trick
