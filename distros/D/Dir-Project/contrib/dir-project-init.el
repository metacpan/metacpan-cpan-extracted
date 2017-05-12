;; dir-project-init.el --- site-start for dir-project.el
;; See dir-project.el for documentation and copyright.

(autoload 'dir-project-verilog-getopt "dir-project"
  "Resolve project/ for verilog-mode.el.")
(add-hook 'verilog-getopt-flags-hook 'dir-project-verilog-getopt)
