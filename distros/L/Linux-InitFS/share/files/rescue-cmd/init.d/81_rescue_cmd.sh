
###############################################################################
# argument parser

get_arg_rescue_cmd() {
	local arg="$1"

	case $arg in

		rescue)
			RESCUE=nonempty
			;;

	esac

}

import_handler get_arg_rescue_cmd

