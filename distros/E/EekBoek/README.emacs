The EekBoek kit contains two files to be used with GNU Emacs.

eekboek-mode.el defines the 'eekboek' major mode for editing EekBoek
data files. It is nothing fancy yet.

eekboek-site-init.el contains the necessary autoload settings and type
associations for EekBoek files. 

Place these files according to how your distribution configures GNU
Emacs.

For Fedora systems:

  /usr/share/emacs/site-lisp/site-start.d/eekboek.el
  /usr/share/emacs/site-lisp/eekboek-mode.el

For Debian systems:

  /etc/emacs/site-start.d/50eekboek.el
  /usr/share/emacs/site-lisp/eekboek-mode.el

