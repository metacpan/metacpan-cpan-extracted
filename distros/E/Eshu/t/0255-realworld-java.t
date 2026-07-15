use strict;
use warnings;
use Test::More;
use Eshu;

sub j { Eshu->indent_java($_[0], indent_char => ' ', indent_width => 4) }

# ── already-formatted snippets ─────────────────────────────────────

# 1. simple class
{
    my $code = <<'END';
public class HelloWorld {
    public static void main(String[] args) {
        System.out.println("Hello, World!");
    }
}
END
    is(j($code), $code, 'Java: Hello World');
}

# 2. instance methods
{
    my $code = <<'END';
public class Counter {
    private int count;

    public Counter(int initial) {
        this.count = initial;
    }

    public void increment() {
        count++;
    }

    public void decrement() {
        count--;
    }

    public int getCount() {
        return count;
    }
}
END
    is(j($code), $code, 'Java: counter class');
}

# 3. if/else
{
    my $code = <<'END';
public static String classify(int n) {
    if (n < 0) {
        return "negative";
    } else if (n == 0) {
        return "zero";
    } else {
        return "positive";
    }
}
END
    is(j($code), $code, 'Java: if/else');
}

# 4. for loop
{
    my $code = <<'END';
public static int sum(int[] arr) {
    int total = 0;
    for (int i = 0; i < arr.length; i++) {
        total += arr[i];
    }
    return total;
}
END
    is(j($code), $code, 'Java: for loop');
}

# 5. enhanced for loop
{
    my $code = <<'END';
public static double average(List<Integer> nums) {
    if (nums.isEmpty()) {
        return 0.0;
    }
    long sum = 0;
    for (int n : nums) {
        sum += n;
    }
    return (double) sum / nums.size();
}
END
    is(j($code), $code, 'Java: enhanced for loop');
}

# 6. interface
{
    my $code = <<'END';
public interface Shape {
    double area();
    double perimeter();

    default String describe() {
        return String.format("area=%.2f perimeter=%.2f", area(), perimeter());
    }
}
END
    is(j($code), $code, 'Java: interface with default method');
}

# 7. interface implementation
{
    my $code = <<'END';
public class Circle implements Shape {
    private final double radius;

    public Circle(double radius) {
        if (radius < 0) {
            throw new IllegalArgumentException("Radius must be non-negative");
        }
        this.radius = radius;
    }

    @Override
    public double area() {
        return Math.PI * radius * radius;
    }

    @Override
    public double perimeter() {
        return 2 * Math.PI * radius;
    }
}
END
    is(j($code), $code, 'Java: class implementing interface');
}

# 8. generics
{
    my $code = <<'END';
public class Pair<A, B> {
    private final A first;
    private final B second;

    public Pair(A first, B second) {
        this.first  = first;
        this.second = second;
    }

    public A getFirst()  { return first; }
    public B getSecond() { return second; }

    public static <A, B> Pair<A, B> of(A a, B b) {
        return new Pair<>(a, b);
    }
}
END
    is(j($code), $code, 'Java: generic Pair class');
}

# 9. try-with-resources
{
    my $code = <<'END';
public static String readFile(String path) throws IOException {
    try (BufferedReader reader = new BufferedReader(new FileReader(path))) {
        StringBuilder sb = new StringBuilder();
        String line;
        while ((line = reader.readLine()) != null) {
            sb.append(line).append('\n');
        }
        return sb.toString();
    }
}
END
    is(j($code), $code, 'Java: try-with-resources');
}

# 10. lambda and streams
{
    my $code = <<'END';
public static List<String> processNames(List<String> names) {
    return names.stream()
    .filter(name -> name != null && !name.isEmpty())
    .map(String::trim)
    .map(String::toLowerCase)
    .sorted()
    .distinct()
    .collect(Collectors.toList());
}
END
    is(j($code), $code, 'Java: stream with lambdas');
}

# 11. Optional
{
    my $code = <<'END';
public Optional<User> findActiveUser(long id) {
    return userRepo.findById(id)
    .filter(User::isActive)
    .map(user -> {
        user.setLastSeen(Instant.now());
        return user;
    });
}
END
    is(j($code), $code, 'Java: Optional chaining');
}

# 12. enum
{
    my $code = <<'END';
public enum Status {
    PENDING("Pending"),
    ACTIVE("Active"),
    CANCELLED("Cancelled"),
    DONE("Done");

    private final String label;

    Status(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }

    public boolean isTerminal() {
        return this == CANCELLED || this == DONE;
    }
}
END
    is(j($code), $code, 'Java: enum with methods');
}

# 13. record
{
    my $code = <<'END';
public record Point(double x, double y) {
    public Point {
        if (Double.isNaN(x) || Double.isNaN(y)) {
            throw new IllegalArgumentException("NaN coordinates");
        }
    }

    public double distance(Point other) {
        double dx = this.x - other.x;
        double dy = this.y - other.y;
        return Math.sqrt(dx * dx + dy * dy);
    }

    public Point translate(double dx, double dy) {
        return new Point(x + dx, y + dy);
    }
}
END
    is(j($code), $code, 'Java: record class');
}

# 14. switch expression
{
    my $code = <<'END';
public static int daysInMonth(int month, int year) {
    return switch (month) {
        case 1, 3, 5, 7, 8, 10, 12 -> 31;
        case 4, 6, 9, 11            -> 30;
        case 2 -> (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) ? 29 : 28;
        default -> throw new IllegalArgumentException("Invalid month: " + month);
    };
}
END
    is(j($code), $code, 'Java: switch expression');
}

# 15. annotation
{
    my $code = <<'END';
@Retention(RetentionPolicy.RUNTIME)
@Target({ElementType.METHOD, ElementType.TYPE})
public @interface Cacheable {
    String key() default "";
    int ttl() default 300;
    boolean evictAll() default false;
}
END
    is(j($code), $code, 'Java: custom annotation');
}

# 16. abstract class
{
    my $code = <<'END';
public abstract class Template {
    public final void execute() {
        setup();
        doWork();
        teardown();
    }

    protected void setup() {
        // default: no-op
    }

    protected abstract void doWork();

    protected void teardown() {
        // default: no-op
    }
}
END
    is(j($code), $code, 'Java: template method pattern');
}

# 17. Builder pattern
{
    my $code = <<'END';
public class HttpRequest {
    private final String url;
    private final String method;
    private final Map<String, String> headers;
    private final String body;

    private HttpRequest(Builder builder) {
        this.url     = builder.url;
        this.method  = builder.method;
        this.headers = Collections.unmodifiableMap(new HashMap<>(builder.headers));
        this.body    = builder.body;
    }

    public static class Builder {
        private String url;
        private String method = "GET";
        private Map<String, String> headers = new HashMap<>();
        private String body;

        public Builder url(String url) {
            this.url = url;
            return this;
        }

        public Builder method(String method) {
            this.method = method;
            return this;
        }

        public Builder header(String key, String value) {
            this.headers.put(key, value);
            return this;
        }

        public Builder body(String body) {
            this.body = body;
            return this;
        }

        public HttpRequest build() {
            Objects.requireNonNull(url, "URL is required");
            return new HttpRequest(this);
        }
    }
}
END
    is(j($code), $code, 'Java: Builder pattern');
}

# 18. synchronized
{
    my $code = <<'END';
public class ThreadSafeCounter {
    private int count = 0;

    public synchronized void increment() {
        count++;
    }

    public synchronized void decrement() {
        count--;
    }

    public synchronized int get() {
        return count;
    }

    public synchronized void reset() {
        count = 0;
    }
}
END
    is(j($code), $code, 'Java: synchronized methods');
}

# 19. Comparable
{
    my $code = <<'END';
public class Version implements Comparable<Version> {
    private final int major;
    private final int minor;
    private final int patch;

    public Version(int major, int minor, int patch) {
        this.major = major;
        this.minor = minor;
        this.patch = patch;
    }

    @Override
    public int compareTo(Version other) {
        if (this.major != other.major) return Integer.compare(this.major, other.major);
        if (this.minor != other.minor) return Integer.compare(this.minor, other.minor);
        return Integer.compare(this.patch, other.patch);
    }

    @Override
    public String toString() {
        return major + "." + minor + "." + patch;
    }
}
END
    is(j($code), $code, 'Java: Comparable implementation');
}

# 20. Iterator pattern
{
    my $code = <<'END';
public class RangeIterator implements Iterator<Integer>, Iterable<Integer> {
    private int current;
    private final int end;
    private final int step;

    public RangeIterator(int start, int end, int step) {
        this.current = start;
        this.end     = end;
        this.step    = step;
    }

    @Override
    public boolean hasNext() {
        return step > 0 ? current < end : current > end;
    }

    @Override
    public Integer next() {
        if (!hasNext()) throw new NoSuchElementException();
        int value = current;
        current += step;
        return value;
    }

    @Override
    public Iterator<Integer> iterator() {
        return this;
    }
}
END
    is(j($code), $code, 'Java: Iterator pattern');
}

# 21. Functional interface
{
    my $code = <<'END';
@FunctionalInterface
public interface Transformer<T, R> {
    R transform(T input);

    default <V> Transformer<T, V> andThen(Transformer<R, V> after) {
        return input -> after.transform(this.transform(input));
    }
}
END
    is(j($code), $code, 'Java: functional interface');
}

# 22. CompletableFuture
{
    my $code = <<'END';
public CompletableFuture<User> fetchUserAsync(long id) {
    return CompletableFuture
    .supplyAsync(() -> userRepo.findById(id))
    .thenApply(optUser -> optUser.orElseThrow(() ->
    new NotFoundException("User " + id + " not found")))
    .exceptionally(ex -> {
        log.error("Failed to fetch user {}: {}", id, ex.getMessage());
        throw new RuntimeException(ex);
    });
}
END
    is(j($code), $code, 'Java: CompletableFuture');
}

# 23. varargs
{
    my $code = <<'END';
public static <T> List<T> listOf(T... items) {
    List<T> list = new ArrayList<>(items.length);
    for (T item : items) {
        if (item != null) {
            list.add(item);
        }
    }
    return Collections.unmodifiableList(list);
}
END
    is(j($code), $code, 'Java: varargs');
}

# 24. nested class
{
    my $code = <<'END';
public class LinkedList<T> {
    private static class Node<T> {
        T data;
        Node<T> next;

        Node(T data) {
            this.data = data;
            this.next = null;
        }
    }

    private Node<T> head;
    private int size;

    public void push(T data) {
        Node<T> node = new Node<>(data);
        node.next = head;
        head = node;
        size++;
    }

    public T pop() {
        if (head == null) throw new NoSuchElementException();
        T data = head.data;
        head = head.next;
        size--;
        return data;
    }

    public int size() {
        return size;
    }
}
END
    is(j($code), $code, 'Java: linked list with nested class');
}

# 25. HashMap operations
{
    my $code = <<'END';
public static <K, V> Map<V, List<K>> invertMap(Map<K, V> map) {
    Map<V, List<K>> result = new HashMap<>();
    for (Map.Entry<K, V> entry : map.entrySet()) {
        result.computeIfAbsent(entry.getValue(), k -> new ArrayList<>())
        .add(entry.getKey());
    }
    return result;
}
END
    is(j($code), $code, 'Java: invert map with computeIfAbsent');
}

# ── normalization tests ────────────────────────────────────────────

# 26
{
    my $in = <<'END';
public static long factorial(int n) {
if (n < 0) throw new IllegalArgumentException("negative");
if (n <= 1) return 1;
return n * factorial(n - 1);
}
END
    my $exp = <<'END';
public static long factorial(int n) {
    if (n < 0) throw new IllegalArgumentException("negative");
    if (n <= 1) return 1;
    return n * factorial(n - 1);
}
END
    is(j($in), $exp, 'Java: unindented factorial normalised');
}

# 27
{
    my $in = <<'END';
public static int binarySearch(int[] arr, int target) {
int lo = 0, hi = arr.length - 1;
while (lo <= hi) {
int mid = lo + (hi - lo) / 2;
if (arr[mid] == target) {
return mid;
} else if (arr[mid] < target) {
lo = mid + 1;
} else {
hi = mid - 1;
}
}
return -1;
}
END
    my $exp = <<'END';
public static int binarySearch(int[] arr, int target) {
    int lo = 0, hi = arr.length - 1;
    while (lo <= hi) {
        int mid = lo + (hi - lo) / 2;
        if (arr[mid] == target) {
            return mid;
        } else if (arr[mid] < target) {
            lo = mid + 1;
        } else {
            hi = mid - 1;
        }
    }
    return -1;
}
END
    is(j($in), $exp, 'Java: unindented binary search normalised');
}

# 28
{
    my $in = <<'END';
public class Stack<T> {
private final Deque<T> deque = new ArrayDeque<>();
public void push(T item) {
deque.push(item);
}
public T pop() {
if (deque.isEmpty()) throw new EmptyStackException();
return deque.pop();
}
public T peek() {
if (deque.isEmpty()) throw new EmptyStackException();
return deque.peek();
}
public boolean isEmpty() {
return deque.isEmpty();
}
}
END
    my $exp = <<'END';
public class Stack<T> {
    private final Deque<T> deque = new ArrayDeque<>();
    public void push(T item) {
        deque.push(item);
    }
    public T pop() {
        if (deque.isEmpty()) throw new EmptyStackException();
        return deque.pop();
    }
    public T peek() {
        if (deque.isEmpty()) throw new EmptyStackException();
        return deque.peek();
    }
    public boolean isEmpty() {
        return deque.isEmpty();
    }
}
END
    is(j($in), $exp, 'Java: unindented generic Stack normalised');
}

# 29
{
    my $in = <<'END';
public static <T extends Comparable<T>> void insertionSort(T[] arr) {
for (int i = 1; i < arr.length; i++) {
T key = arr[i];
int j = i - 1;
while (j >= 0 && arr[j].compareTo(key) > 0) {
arr[j + 1] = arr[j];
j--;
}
arr[j + 1] = key;
}
}
END
    my $exp = <<'END';
public static <T extends Comparable<T>> void insertionSort(T[] arr) {
    for (int i = 1; i < arr.length; i++) {
        T key = arr[i];
        int j = i - 1;
        while (j >= 0 && arr[j].compareTo(key) > 0) {
            arr[j + 1] = arr[j];
            j--;
        }
        arr[j + 1] = key;
    }
}
END
    is(j($in), $exp, 'Java: unindented insertion sort normalised');
}

# 30
{
    my $in = <<'END';
public static Map<String, Long> wordFrequency(String text) {
return Arrays.stream(text.toLowerCase().split("\\W+"))
.filter(w -> !w.isEmpty())
.collect(Collectors.groupingBy(w -> w, Collectors.counting()));
}
END
    my $exp = <<'END';
public static Map<String, Long> wordFrequency(String text) {
    return Arrays.stream(text.toLowerCase().split("\\W+"))
    .filter(w -> !w.isEmpty())
    .collect(Collectors.groupingBy(w -> w, Collectors.counting()));
}
END
    is(j($in), $exp, 'Java: unindented word frequency normalised');
}

# ── idempotency tests ──────────────────────────────────────────────

for my $snippet (
    "public class Singleton{\nprivate static volatile Singleton instance;\nprivate Singleton(){}\npublic static Singleton getInstance(){\nif(instance==null){\nsynchronized(Singleton.class){\nif(instance==null)instance=new Singleton();\n}\n}\nreturn instance;\n}\n}\n",
    "public static <T> List<T> filter(List<T> list,Predicate<T> pred){\nreturn list.stream().filter(pred).collect(Collectors.toList());\n}\npublic static <T,U> List<U> map(List<T> list,Function<T,U> fn){\nreturn list.stream().map(fn).collect(Collectors.toList());\n}\n",
    "public class Result<T>{\nprivate final T value;\nprivate final String error;\nprivate Result(T v,String e){value=v;error=e;}\npublic static <T> Result<T> ok(T v){return new Result<>(v,null);}\npublic static <T> Result<T> err(String e){return new Result<>(null,e);}\npublic boolean isOk(){return error==null;}\npublic T getValue(){return value;}\npublic String getError(){return error;}\n}\n",
    "public static int[] twoSum(int[] nums,int target){\nMap<Integer,Integer> seen=new HashMap<>();\nfor(int i=0;i<nums.length;i++){\nint complement=target-nums[i];\nif(seen.containsKey(complement))return new int[]{seen.get(complement),i};\nseen.put(nums[i],i);\n}\nreturn new int[]{};\n}\n",
    "public class Trie{\nprivate Trie[] children=new Trie[26];\nprivate boolean terminal;\npublic void insert(String word){\nTrie cur=this;\nfor(char c:word.toCharArray()){\nint i=c-'a';\nif(cur.children[i]==null)cur.children[i]=new Trie();\ncur=cur.children[i];\n}\ncur.terminal=true;\n}\npublic boolean search(String word){\nTrie cur=this;\nfor(char c:word.toCharArray()){\nint i=c-'a';\nif(cur.children[i]==null)return false;\ncur=cur.children[i];\n}\nreturn cur.terminal;\n}\n}\n",
    "public static int maxSubArray(int[] nums){\nint best=nums[0],cur=nums[0];\nfor(int i=1;i<nums.length;i++){\ncur=Math.max(nums[i],cur+nums[i]);\nbest=Math.max(best,cur);\n}\nreturn best;\n}\n",
    "public static boolean isPalindrome(String s){\nint l=0,r=s.length()-1;\nwhile(l<r){\nwhile(l<r&&!Character.isLetterOrDigit(s.charAt(l)))l++;\nwhile(l<r&&!Character.isLetterOrDigit(s.charAt(r)))r--;\nif(Character.toLowerCase(s.charAt(l))!=Character.toLowerCase(s.charAt(r)))return false;\nl++;r--;\n}\nreturn true;\n}\n",
    "public static List<List<Integer>> permutations(int[] nums){\nList<List<Integer>> result=new ArrayList<>();\nbacktrack(result,new ArrayList<>(),nums,new boolean[nums.length]);\nreturn result;\n}\nprivate static void backtrack(List<List<Integer>> res,List<Integer> cur,int[] nums,boolean[] used){\nif(cur.size()==nums.length){res.add(new ArrayList<>(cur));return;}\nfor(int i=0;i<nums.length;i++){\nif(used[i])continue;\nused[i]=true;cur.add(nums[i]);\nbacktrack(res,cur,nums,used);\nused[i]=false;cur.remove(cur.size()-1);\n}\n}\n",
    "public static <T> Optional<T> findFirst(List<T> list,Predicate<T> pred){\nreturn list.stream().filter(pred).findFirst();\n}\npublic static <T> long count(List<T> list,Predicate<T> pred){\nreturn list.stream().filter(pred).count();\n}\npublic static <T extends Comparable<T>> Optional<T> max(List<T> list){\nreturn list.stream().max(Comparator.naturalOrder());\n}\n",
    "public class EventBus{\nprivate static final Map<String,List<Consumer<Object>>> listeners=new ConcurrentHashMap<>();\npublic static void on(String event,Consumer<Object> fn){\nlisteners.computeIfAbsent(event,k->new CopyOnWriteArrayList<>()).add(fn);\n}\npublic static void emit(String event,Object payload){\nlisteners.getOrDefault(event,List.of()).forEach(fn->fn.accept(payload));\n}\n}\n",
) {
    my $once = j($snippet);
    is(j($once), $once, 'Java: snippet idempotent');
}

done_testing;
