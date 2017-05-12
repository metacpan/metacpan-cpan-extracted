## md2phpBB

This software was done in the bare minimum time to scratch an itch I had.

If you ask me nicely, I'll write some docs and pop it on the CPAN.

I also *love* patches. Please send them to me. :)

## Installing:

This requires `Dist::Zilla` to install.

    $ git clone https://github.com/pjf/Markdown-phpBB.git
    $ cd Markdown-phpBB
    $ dzil install

## Running:

    $ md2phpbb somefile.md       # Convert from file
    $ echo "*Hello*" | md2phpbb  # ...or from STDIN

Output is always sent to STDOUT.

## Why?

I found that phpBB syntax keeps getting in the way, but some of my
favourite communities still use it. I use vimperator and vim to write
all my text, so a command which lets me write in markdown and convert
to phpBB was obvious.

Of most use is `%!md2phpbb` in vim, which will replace your current
buffer (written in markdown) with the phpBB equivalent code. You can even
bind it to a key (place in your `~/.vimrc` file):

    :nmap <F5> :%!md2phpbb<CR>

If you're using vimperator, phpBB will get in the way of using CTRL-I to
invoke vim. You can allow CTRL-E (or another key of your choice) to also
invoke the editor by adding the following to your `~/.vimperatorrc` file:

    :inoremap <C-e> <C-i>

Enjoy!
