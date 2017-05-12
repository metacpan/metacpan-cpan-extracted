(require file)

(file#open ( append  ">" tempfile )  (fn [f]
  (file#>> f "aaa")))

(file#open ( append  "<" tempfile )  (fn [f]
  (println (perl->clj (file#<< f)))))
