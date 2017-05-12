find . \( -name blib -prune -false \) -o \( -name '*.pl' -o -name '*.pm' \) -print | xargs egrep -h '^use [A-Z]' | sed -e's/\( [^ ]*\) .*/\1/' -e 's/;//' -e 's/^use //' | sort | uniq | grep -v Link_Controller

#local modules that come out but shouldn't
#LWP::NoStopRobot
#LWP::Auth_UA
  


