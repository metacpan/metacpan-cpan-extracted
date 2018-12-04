
###############################################################################
# drop to a rescue shell

rescue_shell() {
	local rc
	local run='setsid -c /bin/sh -l'
	echo
	echo 'RESCUE SHELL: (exit or ^d to continue)'
	echo
	(
		export HOME=/root
		cd $HOME
		set +x
		echo "+ $run" >&2 # force trace entry
		$run </dev/console >/dev/console 2>&1
	)
	rc=$?
	echo
	echo 'rescue shell returned' "$rc"
	echo
	return $rc
}

