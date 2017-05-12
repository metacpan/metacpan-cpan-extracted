#!/bin/bash
cd bin;
for file in git-* ; do
    chmod -v +x $file
    ln -svf $PWD/$file ~/bin/$file
done
