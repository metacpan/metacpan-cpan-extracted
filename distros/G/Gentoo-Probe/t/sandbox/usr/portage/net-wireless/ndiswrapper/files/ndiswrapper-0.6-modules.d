# Options for ndiswrapper.
#

# Set this alias to some device. Usually wlan0 unless you've got more than one
# wireless card.

#alias wlan0 ndiswrapper

# loadndisdriver requires 4 parameters.
# 
# Uncomment the following line after you've replaced "REPLACE"
# to the directory in /etc/ndiswrapper created by running with the path to the 
# Windows(tm) .inf file:
#
# ndiswrapper -i somedriver.inf
#

#install ndiswrapper /sbin/modprobe --ignore-install ndiswrapper && { loadndisdriver /etc/ndiswrapper/REPLACE ; }
