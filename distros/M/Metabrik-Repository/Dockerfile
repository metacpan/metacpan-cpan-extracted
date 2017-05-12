FROM ubuntu:yakkety

RUN apt-get -y update
RUN apt-get -y upgrade

#
# Set locale
#
RUN locale-gen en_GB.UTF-8
RUN update-locale LANG=en_GB.UTF-8

#
# Avoid being prompted to set some options
#
RUN apt-get install -y debconf-utils
RUN echo 'console-setup	console-setup/charmap47	select	UTF-8' | debconf-set-selections
RUN echo 'console-setup	console-setup/fontsize-text47	select	8x16' | debconf-set-selections
RUN echo 'console-setup	console-setup/fontsize	string	8x16' | debconf-set-selections
RUN echo 'console-setup	console-setup/codeset47	select	. Combined - Latin; Slavic Cyrillic; Greek' | debconf-set-selections
RUN echo 'console-setup	console-setup/fontsize-fb47	select	8x16' | debconf-set-selections
RUN echo 'console-setup	console-setup/codesetcode	string	Uni2' | debconf-set-selections
RUN echo 'console-setup	console-setup/fontface47	select	Fixed' | debconf-set-selections
RUN echo 'console-setup	console-setup/store_defaults_in_debconf_db	boolean	true' | debconf-set-selections
RUN echo 'keyboard-configuration	keyboard-configuration/modelcode	string	pc105' | debconf-set-selections
RUN echo 'keyboard-configuration	console-setup/detect	detect-keyboard	' | debconf-set-selections
RUN echo 'keyboard-configuration	keyboard-configuration/unsupported_layout	boolean	true' | debconf-set-selections
RUN echo 'keyboard-configuration	keyboard-configuration/model	select	Generic 105-key (Intl) PC' | debconf-set-selections
RUN echo 'keyboard-configuration	keyboard-configuration/store_defaults_in_debconf_db	boolean	true' | debconf-set-selections
RUN echo 'keyboard-configuration	keyboard-configuration/switch	select	No temporary switch' | debconf-set-selections
RUN echo 'keyboard-configuration	keyboard-configuration/variantcode	string	latin9' | debconf-set-selections
RUN echo 'keyboard-configuration	keyboard-configuration/unsupported_config_layout	boolean	true' | debconf-set-selections
RUN echo 'keyboard-configuration	keyboard-configuration/unsupported_config_options	boolean	true' | debconf-set-selections
RUN echo 'keyboard-configuration	keyboard-configuration/toggle	select	No toggling' | debconf-set-selections
RUN echo 'keyboard-configuration	keyboard-configuration/compose	select	No compose key' | debconf-set-selections
RUN echo 'keyboard-configuration	keyboard-configuration/ctrl_alt_bksp	boolean	false' | debconf-set-selections
RUN echo 'keyboard-configuration	keyboard-configuration/layout	select	French' | debconf-set-selections
RUN echo 'keyboard-configuration	keyboard-configuration/unsupported_options	boolean	true' | debconf-set-selections
RUN echo 'keyboard-configuration	keyboard-configuration/xkb-keymap	select	fr(latin9)' | debconf-set-selections
RUN echo 'keyboard-configuration	keyboard-configuration/layoutcode	string	fr' | debconf-set-selections
RUN echo 'keyboard-configuration	keyboard-configuration/optionscode	string	' | debconf-set-selections
RUN echo 'keyboard-configuration	console-setup/ask_detect	boolean	false' | debconf-set-selections
RUN echo 'keyboard-configuration	keyboard-configuration/variant	select	French - French (legacy, alternative)' | debconf-set-selections
RUN echo 'keyboard-configuration	keyboard-configuration/altgr	select	The default for the keyboard layout' | debconf-set-selections
RUN echo 'keyboard-configuration	console-setup/detected	note' | debconf-set-selections

#
# Packages required by Metabrik::Core
#
# Packaged programs
#
RUN apt-get install -y build-essential sudo less cpanminus nvi iputils-ping mercurial libreadline-dev
#
# Perl modules
#
RUN cpanm -n Metabrik
RUN cpanm -n Metabrik::Repository

#
# Update Metabrik to latest head
#
RUN mkdir -p /root/metabrik/brik-tool
RUN perl -MMetabrik::Core::Context -e 'Metabrik::Core::Context->new_brik_run("brik::tool","update")'

# Initialise the environment
RUN perl -MMetabrik::Core::Context -e 'Metabrik::Core::Context->new_brik_run("shell::rc", "write_default")'
RUN echo 'use shell::command' >> /root/.metabrik_rc
RUN echo 'use shell::history' >> /root/.metabrik_rc
RUN echo 'use brik::tool' >> /root/.metabrik_rc
RUN echo 'use brik::search' >> /root/.metabrik_rc
RUN echo 'alias ! "run shell::history exec"' >> /root/.metabrik_rc
RUN echo 'alias history "run shell::history show"' >> /root/.metabrik_rc
RUN echo 'set core::shell ps1 docker' >> /root/.metabrik_rc
RUN echo 'alias ls "run shell::command capture ls -Fh"' >> /root/.metabrik_rc
RUN echo 'alias l "run shell::command capture ls -lFh"' >> /root/.metabrik_rc
RUN echo 'alias ll "run shell::command capture ls -lFh"' >> /root/.metabrik_rc
RUN echo 'run shell::history load' >> /root/.metabrik_rc

# Install dependencies
RUN perl -MMetabrik::Core::Context -e 'Metabrik::Core::Context->new_brik_run("brik::tool","install_all_need_packages")'
RUN perl -MMetabrik::Core::Context -e 'Metabrik::Core::Context->new_brik_run("brik::tool","install_all_require_modules")'

CMD ["/usr/local/bin/metabrik.sh"]
