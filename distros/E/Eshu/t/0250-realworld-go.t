use strict;
use warnings;
use Test::More;
use Eshu;

sub go { Eshu->indent_go($_[0]) }

# ── already-formatted snippets pass through unchanged ──────────────

# 1. simple function
{
	my $code = <<'END';
func greet(name string) string {
	return "Hello, " + name
}
END
	is(go($code), $code, 'Go: simple function');
}

# 2. function with error return
{
	my $code = <<'END';
func divide(a, b float64) (float64, error) {
	if b == 0 {
		return 0, fmt.Errorf("division by zero")
	}
	return a / b, nil
}
END
	is(go($code), $code, 'Go: function returning error');
}

# 3. if/else chain
{
	my $code = <<'END';
func classify(n int) string {
	if n < 0 {
		return "negative"
	} else if n == 0 {
		return "zero"
	} else {
		return "positive"
	}
}
END
	is(go($code), $code, 'Go: if/else chain');
}

# 4. for range loop
{
	my $code = <<'END';
func sum(nums []int) int {
	total := 0
	for _, v := range nums {
		total += v
	}
	return total
}
END
	is(go($code), $code, 'Go: for-range sum');
}

# 5. struct definition
{
	my $code = <<'END';
type Point struct {
	X float64
	Y float64
}
END
	is(go($code), $code, 'Go: struct definition');
}

# 6. method on struct
{
	my $code = <<'END';
func (p Point) Distance(q Point) float64 {
	dx := p.X - q.X
	dy := p.Y - q.Y
	return math.Sqrt(dx*dx + dy*dy)
}
END
	is(go($code), $code, 'Go: method on struct');
}

# 7. interface definition
{
	my $code = <<'END';
type Writer interface {
	Write(p []byte) (n int, err error)
	Flush() error
}
END
	is(go($code), $code, 'Go: interface definition');
}

# 8. goroutine and channel
{
	my $code = <<'END';
func produce(ch chan<- int, n int) {
	for i := 0; i < n; i++ {
		ch <- i
	}
	close(ch)
}
END
	is(go($code), $code, 'Go: goroutine producer');
}

# 9. select on channels
{
	my $code = <<'END';
func fanIn(a, b <-chan string) <-chan string {
	ch := make(chan string)
	go func() {
		for {
			select {
			case v := <-a:
				ch <- v
			case v := <-b:
				ch <- v
			}
		}
	}()
	return ch
}
END
	is(go($code), $code, 'Go: select fan-in');
}

# 10. defer statement
{
	my $code = <<'END';
func withFile(path string, fn func(*os.File) error) error {
	f, err := os.Open(path)
	if err != nil {
		return err
	}
	defer f.Close()
	return fn(f)
}
END
	is(go($code), $code, 'Go: defer file close');
}

# 11. error wrapping
{
	my $code = <<'END';
func loadConfig(path string) (*Config, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("loadConfig: %w", err)
	}
	var cfg Config
	if err := json.Unmarshal(data, &cfg); err != nil {
		return nil, fmt.Errorf("loadConfig: parse: %w", err)
	}
	return &cfg, nil
}
END
	is(go($code), $code, 'Go: error wrapping with fmt.Errorf');
}

# 12. slice manipulation
{
	my $code = <<'END';
func filter(s []int, fn func(int) bool) []int {
	out := make([]int, 0, len(s))
	for _, v := range s {
		if fn(v) {
			out = append(out, v)
		}
	}
	return out
}
END
	is(go($code), $code, 'Go: filter slice');
}

# 13. map operations
{
	my $code = <<'END';
func wordCount(s string) map[string]int {
	counts := make(map[string]int)
	for _, word := range strings.Fields(s) {
		counts[word]++
	}
	return counts
}
END
	is(go($code), $code, 'Go: word count with map');
}

# 14. closure
{
	my $code = <<'END';
func makeCounter() func() int {
	n := 0
	return func() int {
		n++
		return n
	}
}
END
	is(go($code), $code, 'Go: closure counter');
}

# 15. sync.WaitGroup pattern
{
	my $code = <<'END';
func parallel(tasks []Task) {
	var wg sync.WaitGroup
	for _, t := range tasks {
		wg.Add(1)
		go func(t Task) {
			defer wg.Done()
			t.Run()
		}(t)
	}
	wg.Wait()
}
END
	is(go($code), $code, 'Go: sync.WaitGroup parallel tasks');
}

# 16. http.Handler implementation
{
	my $code = <<'END';
type helloHandler struct {
	message string
}

func (h helloHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	fmt.Fprintln(w, h.message)
}
END
	is(go($code), $code, 'Go: http.Handler implementation');
}

# 17. table-driven test pattern
{
	my $code = <<'END';
func TestAdd(t *testing.T) {
	cases := []struct {
		a, b, want int
	}{
		{1, 2, 3},
		{-1, 1, 0},
		{0, 0, 0},
	}
	for _, tc := range cases {
		got := add(tc.a, tc.b)
		if got != tc.want {
			t.Errorf("add(%d,%d) = %d; want %d", tc.a, tc.b, got, tc.want)
		}
	}
}
END
	is(go($code), $code, 'Go: table-driven test');
}

# 18. context with cancel
{
	my $code = <<'END';
func runWithTimeout(timeout time.Duration, fn func(ctx context.Context)) {
	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()
	fn(ctx)
}
END
	is(go($code), $code, 'Go: context with timeout');
}

# 19. embedding
{
	my $code = <<'END';
type Animal struct {
	Name string
}

func (a Animal) Speak() string {
	return a.Name + " speaks"
}

type Dog struct {
	Animal
	Breed string
}
END
	is(go($code), $code, 'Go: struct embedding');
}

# 20. variadic function
{
	my $code = <<'END';
func join(sep string, parts ...string) string {
	return strings.Join(parts, sep)
}
END
	is(go($code), $code, 'Go: variadic function');
}

# 21. panic/recover
{
	my $code = <<'END';
func safeDiv(a, b int) (result int, err error) {
	defer func() {
		if r := recover(); r != nil {
			err = fmt.Errorf("panic: %v", r)
		}
	}()
	return a / b, nil
}
END
	is(go($code), $code, 'Go: panic/recover pattern');
}

# 22. type assertion
{
	my $code = <<'END';
func stringify(v interface{}) string {
	switch x := v.(type) {
	case string:
		return x
	case int:
		return strconv.Itoa(x)
	case fmt.Stringer:
		return x.String()
	default:
		return fmt.Sprintf("%v", v)
	}
}
END
	is(go($code), $code, 'Go: type switch');
}

# 23. channel pipeline
{
	my $code = <<'END';
func square(in <-chan int) <-chan int {
	out := make(chan int)
	go func() {
		for v := range in {
			out <- v * v
		}
		close(out)
	}()
	return out
}
END
	is(go($code), $code, 'Go: channel pipeline stage');
}

# 24. mutex-protected map
{
	my $code = <<'END';
type SafeMap struct {
	mu sync.RWMutex
	m  map[string]string
}

func (s *SafeMap) Get(key string) (string, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	v, ok := s.m[key]
	return v, ok
}

func (s *SafeMap) Set(key, val string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.m[key] = val
}
END
	is(go($code), $code, 'Go: mutex-protected safe map');
}

# 25. io.Reader wrapper
{
	my $code = <<'END';
type LimitReader struct {
	r   io.Reader
	rem int64
}

func (l *LimitReader) Read(p []byte) (int, error) {
	if l.rem <= 0 {
		return 0, io.EOF
	}
	if int64(len(p)) > l.rem {
		p = p[:l.rem]
	}
	n, err := l.r.Read(p)
	l.rem -= int64(n)
	return n, err
}
END
	is(go($code), $code, 'Go: custom io.Reader wrapper');
}

# 26. builder pattern
{
	my $code = <<'END';
type QueryBuilder struct {
	table  string
	wheres []string
	limit  int
}

func (q *QueryBuilder) Where(cond string) *QueryBuilder {
	q.wheres = append(q.wheres, cond)
	return q
}

func (q *QueryBuilder) Limit(n int) *QueryBuilder {
	q.limit = n
	return q
}
END
	is(go($code), $code, 'Go: builder pattern');
}

# 27. functional options
{
	my $code = <<'END';
type ServerOption func(*Server)

func WithPort(port int) ServerOption {
	return func(s *Server) {
		s.port = port
	}
}

func WithTimeout(d time.Duration) ServerOption {
	return func(s *Server) {
		s.timeout = d
	}
}
END
	is(go($code), $code, 'Go: functional options');
}

# 28. error type
{
	my $code = <<'END';
type ValidationError struct {
	Field   string
	Message string
}

func (e *ValidationError) Error() string {
	return fmt.Sprintf("validation error: %s: %s", e.Field, e.Message)
}
END
	is(go($code), $code, 'Go: custom error type');
}

# 29. generics (Go 1.18+)
{
	my $code = <<'END';
func Map[T, U any](s []T, fn func(T) U) []U {
	out := make([]U, len(s))
	for i, v := range s {
		out[i] = fn(v)
	}
	return out
}
END
	is(go($code), $code, 'Go: generic Map function');
}

# 30. init function
{
	my $code = <<'END';
var db *sql.DB

func init() {
	var err error
	db, err = sql.Open("postgres", os.Getenv("DATABASE_URL"))
	if err != nil {
		log.Fatalf("db open: %v", err)
	}
}
END
	is(go($code), $code, 'Go: init function');
}

# ── normalization tests ────────────────────────────────────────────

# 31
{
	my $in = <<'END';
func abs(n int) int {
if n < 0 {
return -n
}
return n
}
END
	my $exp = <<'END';
func abs(n int) int {
	if n < 0 {
		return -n
	}
	return n
}
END
	is(go($in), $exp, 'Go: unindented abs normalised');
}

# 32
{
	my $in = <<'END';
func max(a, b int) int {
if a > b {
return a
}
return b
}
END
	my $exp = <<'END';
func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}
END
	is(go($in), $exp, 'Go: unindented max normalised');
}

# 33
{
	my $in = <<'END';
func reverseSlice(s []int) {
for i, j := 0, len(s)-1; i < j; i, j = i+1, j-1 {
s[i], s[j] = s[j], s[i]
}
}
END
	my $exp = <<'END';
func reverseSlice(s []int) {
	for i, j := 0, len(s)-1; i < j; i, j = i+1, j-1 {
		s[i], s[j] = s[j], s[i]
	}
}
END
	is(go($in), $exp, 'Go: unindented reverse slice normalised');
}

# 34
{
	my $in = <<'END';
func contains(s []string, target string) bool {
for _, v := range s {
if v == target {
return true
}
}
return false
}
END
	my $exp = <<'END';
func contains(s []string, target string) bool {
	for _, v := range s {
		if v == target {
			return true
		}
	}
	return false
}
END
	is(go($in), $exp, 'Go: unindented contains normalised');
}

# 35
{
	my $in = <<'END';
func fibonacci(n int) []int {
if n <= 0 {
return nil
}
seq := make([]int, n)
seq[0] = 0
if n > 1 {
seq[1] = 1
}
for i := 2; i < n; i++ {
seq[i] = seq[i-1] + seq[i-2]
}
return seq
}
END
	my $exp = <<'END';
func fibonacci(n int) []int {
	if n <= 0 {
		return nil
	}
	seq := make([]int, n)
	seq[0] = 0
	if n > 1 {
		seq[1] = 1
	}
	for i := 2; i < n; i++ {
		seq[i] = seq[i-1] + seq[i-2]
	}
	return seq
}
END
	is(go($in), $exp, 'Go: unindented fibonacci normalised');
}

# 36
{
	my $in = <<'END';
type Stack struct {
items []interface{}
}
func (s *Stack) Push(v interface{}) {
s.items = append(s.items, v)
}
func (s *Stack) Pop() (interface{}, bool) {
if len(s.items) == 0 {
return nil, false
}
n := len(s.items) - 1
v := s.items[n]
s.items = s.items[:n]
return v, true
}
END
	my $exp = <<'END';
type Stack struct {
	items []interface{}
}
func (s *Stack) Push(v interface{}) {
	s.items = append(s.items, v)
}
func (s *Stack) Pop() (interface{}, bool) {
	if len(s.items) == 0 {
		return nil, false
	}
	n := len(s.items) - 1
	v := s.items[n]
	s.items = s.items[:n]
	return v, true
}
END
	is(go($in), $exp, 'Go: unindented stack normalised');
}

# 37
{
	my $in = <<'END';
func dedupe(s []string) []string {
seen := make(map[string]struct{})
out := make([]string, 0, len(s))
for _, v := range s {
if _, ok := seen[v]; !ok {
seen[v] = struct{}{}
out = append(out, v)
}
}
return out
}
END
	my $exp = <<'END';
func dedupe(s []string) []string {
	seen := make(map[string]struct{})
	out := make([]string, 0, len(s))
	for _, v := range s {
		if _, ok := seen[v]; !ok {
			seen[v] = struct{}{}
			out = append(out, v)
		}
	}
	return out
}
END
	is(go($in), $exp, 'Go: unindented dedupe normalised');
}

# 38
{
	my $in = <<'END';
func retry(n int, fn func() error) error {
var err error
for i := 0; i < n; i++ {
err = fn()
if err == nil {
return nil
}
}
return fmt.Errorf("failed after %d attempts: %w", n, err)
}
END
	my $exp = <<'END';
func retry(n int, fn func() error) error {
	var err error
	for i := 0; i < n; i++ {
		err = fn()
		if err == nil {
			return nil
		}
	}
	return fmt.Errorf("failed after %d attempts: %w", n, err)
}
END
	is(go($in), $exp, 'Go: unindented retry normalised');
}

# 39
{
	my $in = <<'END';
func chunk(s []int, size int) [][]int {
var out [][]int
for len(s) > 0 {
if len(s) < size {
size = len(s)
}
out = append(out, s[:size])
s = s[size:]
}
return out
}
END
	my $exp = <<'END';
func chunk(s []int, size int) [][]int {
	var out [][]int
	for len(s) > 0 {
		if len(s) < size {
			size = len(s)
		}
		out = append(out, s[:size])
		s = s[size:]
	}
	return out
}
END
	is(go($in), $exp, 'Go: unindented chunk normalised');
}

# 40
{
	my $in = <<'END';
func mergeChans(channels ...<-chan int) <-chan int {
out := make(chan int)
var wg sync.WaitGroup
for _, ch := range channels {
wg.Add(1)
go func(c <-chan int) {
defer wg.Done()
for v := range c {
out <- v
}
}(ch)
}
go func() {
wg.Wait()
close(out)
}()
return out
}
END
	my $exp = <<'END';
func mergeChans(channels ...<-chan int) <-chan int {
	out := make(chan int)
	var wg sync.WaitGroup
	for _, ch := range channels {
		wg.Add(1)
		go func(c <-chan int) {
			defer wg.Done()
			for v := range c {
				out <- v
			}
		}(ch)
	}
	go func() {
		wg.Wait()
		close(out)
	}()
	return out
}
END
	is(go($in), $exp, 'Go: unindented merge channels normalised');
}

# 41
{
	my $in = <<'END';
func flatten(nested [][]int) []int {
var out []int
for _, row := range nested {
out = append(out, row...)
}
return out
}
END
	my $exp = <<'END';
func flatten(nested [][]int) []int {
	var out []int
	for _, row := range nested {
		out = append(out, row...)
	}
	return out
}
END
	is(go($in), $exp, 'Go: unindented flatten normalised');
}

# 42
{
	my $in = <<'END';
func groupBy(s []string, key func(string) string) map[string][]string {
out := make(map[string][]string)
for _, v := range s {
k := key(v)
out[k] = append(out[k], v)
}
return out
}
END
	my $exp = <<'END';
func groupBy(s []string, key func(string) string) map[string][]string {
	out := make(map[string][]string)
	for _, v := range s {
		k := key(v)
		out[k] = append(out[k], v)
	}
	return out
}
END
	is(go($in), $exp, 'Go: unindented groupBy normalised');
}

# 43
{
	my $in = <<'END';
func reduce(s []int, init int, fn func(int, int) int) int {
acc := init
for _, v := range s {
acc = fn(acc, v)
}
return acc
}
END
	my $exp = <<'END';
func reduce(s []int, init int, fn func(int, int) int) int {
	acc := init
	for _, v := range s {
		acc = fn(acc, v)
	}
	return acc
}
END
	is(go($in), $exp, 'Go: unindented reduce normalised');
}

# 44
{
	my $in = <<'END';
func keys(m map[string]int) []string {
ks := make([]string, 0, len(m))
for k := range m {
ks = append(ks, k)
}
sort.Strings(ks)
return ks
}
END
	my $exp = <<'END';
func keys(m map[string]int) []string {
	ks := make([]string, 0, len(m))
	for k := range m {
		ks = append(ks, k)
	}
	sort.Strings(ks)
	return ks
}
END
	is(go($in), $exp, 'Go: unindented sorted keys normalised');
}

# 45
{
	my $in = <<'END';
func zip(a, b []int) [][2]int {
n := len(a)
if len(b) < n {
n = len(b)
}
out := make([][2]int, n)
for i := 0; i < n; i++ {
out[i] = [2]int{a[i], b[i]}
}
return out
}
END
	my $exp = <<'END';
func zip(a, b []int) [][2]int {
	n := len(a)
	if len(b) < n {
		n = len(b)
	}
	out := make([][2]int, n)
	for i := 0; i < n; i++ {
		out[i] = [2]int{a[i], b[i]}
	}
	return out
}
END
	is(go($in), $exp, 'Go: unindented zip normalised');
}

# ── idempotency ────────────────────────────────────────────────────

# 46
{
	my $messy = <<'END';
type LRU struct { cap int; ll *list.List; cache map[interface{}]*list.Element }
func NewLRU(cap int) *LRU { return &LRU{cap: cap, ll: list.New(), cache: make(map[interface{}]*list.Element)} }
func (l *LRU) Get(key interface{}) (interface{}, bool) {
if el, ok := l.cache[key]; ok {
l.ll.MoveToFront(el)
return el.Value, true
}
return nil, false
}
END
	my $once = go($messy);
	is(go($once), $once, 'Go: LRU cache idempotent');
}

# 47
{
	my $messy = <<'END';
func parseFlags() Config {
var cfg Config
flag.StringVar(&cfg.Host, "host", "localhost", "server host")
flag.IntVar(&cfg.Port, "port", 8080, "server port")
flag.BoolVar(&cfg.Debug, "debug", false, "enable debug logging")
flag.Parse()
if cfg.Port < 1 || cfg.Port > 65535 { log.Fatal("invalid port") }
return cfg
}
END
	my $once = go($messy);
	is(go($once), $once, 'Go: flag parsing idempotent');
}

# 48
{
	my $messy = <<'END';
type middleware func(http.Handler) http.Handler
func chain(h http.Handler, mw ...middleware) http.Handler {
for i := len(mw) - 1; i >= 0; i-- {
h = mw[i](h)
}
return h
}
func logging(next http.Handler) http.Handler {
return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
start := time.Now()
next.ServeHTTP(w, r)
log.Printf("%s %s %v", r.Method, r.URL.Path, time.Since(start))
})
}
END
	my $once = go($messy);
	is(go($once), $once, 'Go: middleware chain idempotent');
}

# 49
{
	my $messy = <<'END';
func deepEqual(a, b interface{}) bool {
switch av := a.(type) {
case []interface{}:
bv, ok := b.([]interface{})
if !ok || len(av) != len(bv) { return false }
for i := range av { if !deepEqual(av[i], bv[i]) { return false } }
return true
case map[string]interface{}:
bv, ok := b.(map[string]interface{})
if !ok || len(av) != len(bv) { return false }
for k, v := range av { if !deepEqual(v, bv[k]) { return false } }
return true
default:
return reflect.DeepEqual(a, b)
}
}
END
	my $once = go($messy);
	is(go($once), $once, 'Go: deep equal idempotent');
}

# 50
{
	my $messy = <<'END';
type semaphore chan struct{}
func newSemaphore(n int) semaphore { return make(semaphore, n) }
func (s semaphore) Acquire() { s <- struct{}{} }
func (s semaphore) Release() { <-s }
func bounded(sem semaphore, tasks []func()) {
var wg sync.WaitGroup
for _, t := range tasks {
wg.Add(1)
go func(f func()) {
defer wg.Done()
sem.Acquire()
defer sem.Release()
f()
}(t)
}
wg.Wait()
}
END
	my $once = go($messy);
	is(go($once), $once, 'Go: semaphore bounded concurrency idempotent');
}

done_testing;
