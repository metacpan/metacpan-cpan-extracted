#!examples/ush --horns 1

# Some output at the beginning
preamble
re: This is unicorn-shell version [\d.+]
    You have asked for a shell with 1 horn(s)
fastforward some
    Starting REPL...
    

# ok done with the preamble
    $ print "hello";
    hello

# try out the wait_less_than command
    $ sleep 5 and print "woke up";
wait_less_than 6 seconds
    woke up
