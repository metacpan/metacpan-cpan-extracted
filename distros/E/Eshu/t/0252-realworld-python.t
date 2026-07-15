use strict;
use warnings;
use Test::More;
use Eshu;

sub py { Eshu->indent_python($_[0], indent_char => ' ', indent_width => 4) }

# ── already-formatted snippets ─────────────────────────────────────

# 1. simple function
{
    my $code = <<'END';
def greet(name: str) -> str:
    return f"Hello, {name}!"
END
    is(py($code), $code, 'Python: simple function');
}

# 2. if/elif/else
{
    my $code = <<'END';
def classify(n: int) -> str:
    if n < 0:
        return "negative"
    elif n == 0:
        return "zero"
    else:
        return "positive"
END
    is(py($code), $code, 'Python: if/elif/else');
}

# 3. for loop
{
    my $code = <<'END';
def sum_squares(nums: list[int]) -> int:
    total = 0
    for n in nums:
        total += n * n
    return total
END
    is(py($code), $code, 'Python: for loop');
}

# 4. while loop
{
    my $code = <<'END';
def collatz(n: int) -> list[int]:
    seq = [n]
    while n != 1:
        if n % 2 == 0:
            n //= 2
        else:
            n = 3 * n + 1
        seq.append(n)
    return seq
END
    is(py($code), $code, 'Python: while loop');
}

# 5. class definition
{
    my $code = <<'END';
class Animal:
    def __init__(self, name: str, sound: str) -> None:
        self.name  = name
        self.sound = sound

    def speak(self) -> str:
        return f"{self.name} says {self.sound}"

    def __repr__(self) -> str:
        return f"Animal({self.name!r})"
END
    is(py($code), $code, 'Python: basic class');
}

# 6. class inheritance
{
    my $code = <<'END';
class Dog(Animal):
    def __init__(self, name: str) -> None:
        super().__init__(name, "woof")
        self.tricks: list[str] = []

    def learn(self, trick: str) -> None:
        self.tricks.append(trick)

    def perform(self) -> str:
        if not self.tricks:
            return f"{self.name} knows no tricks"
        return f"{self.name} can: {', '.join(self.tricks)}"
END
    is(py($code), $code, 'Python: class inheritance');
}

# 7. decorator
{
    my $code = <<'END';
import functools
import time

def timed(fn):
    \.wraps(fn)
    def wrapper(*args, **kwargs):
        start = time.perf_counter()
        result = fn(*args, **kwargs)
        elapsed = time.perf_counter() - start
        print(f"{fn.__name__} took {elapsed:.3f}s")
        return result
    return wrapper
END
    is(py($code), $code, 'Python: timing decorator');
}

# 8. context manager
{
    my $code = <<'END';
from contextlib import contextmanager

@contextmanager
def temp_directory():
    import tempfile, shutil
    tmpdir = tempfile.mkdtemp()
    try:
        yield tmpdir
    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)
END
    is(py($code), $code, 'Python: context manager with contextlib');
}

# 9. generator
{
    my $code = <<'END';
def fibonacci():
    a, b = 0, 1
    while True:
        yield a
        a, b = b, a + b

def take(n: int, iterable):
    for i, v in enumerate(iterable):
        if i >= n:
            break
        yield v
END
    is(py($code), $code, 'Python: generator functions');
}

# 10. list/dict comprehension
{
    my $code = <<'END';
def process_records(records: list[dict]) -> dict:
    active  = [r for r in records if r.get("active")]
    by_id   = {r["id"]: r for r in records}
    emails  = {r["id"]: r["email"].lower() for r in active if "email" in r}
    scores  = [r.get("score", 0) for r in active]
    average = sum(scores) / len(scores) if scores else 0.0
    return {"active_count": len(active), "average_score": average, "by_id": by_id, "emails": emails}
END
    is(py($code), $code, 'Python: comprehensions');
}

# 11. dataclass
{
    my $code = <<'END';
from dataclasses import dataclass, field
from typing import Optional

@dataclass
class Config:
    host:    str             = "localhost"
    port:    int             = 8080
    debug:   bool            = False
    tags:    list[str]       = field(default_factory=list)
    timeout: Optional[float] = None

    def base_url(self) -> str:
        return f"http://{self.host}:{self.port}"
END
    is(py($code), $code, 'Python: dataclass');
}

# 12. exception handling
{
    my $code = <<'END';
class AppError(Exception):
    def __init__(self, message: str, code: int = 500) -> None:
        super().__init__(message)
        self.code = code

def load_config(path: str) -> dict:
    try:
        import json
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        raise AppError(f"Config file not found: {path}", code=404)
    except json.JSONDecodeError as e:
        raise AppError(f"Invalid JSON in {path}: {e}", code=400)
END
    is(py($code), $code, 'Python: custom exception and try/except');
}

# 13. async function
{
    my $code = <<'END';
import asyncio
import aiohttp

async def fetch_json(session: aiohttp.ClientSession, url: str) -> dict:
    async with session.get(url) as response:
        response.raise_for_status()
        return await response.json()

async def fetch_all(urls: list[str]) -> list[dict]:
    async with aiohttp.ClientSession() as session:
        tasks = [fetch_json(session, url) for url in urls]
        return await asyncio.gather(*tasks)
END
    is(py($code), $code, 'Python: async/await');
}

# 14. type hints
{
    my $code = <<'END';
from typing import TypeVar, Generic, Callable, Iterator

T = TypeVar("T")
U = TypeVar("U")

class Stream(Generic[T]):
    def __init__(self, items: list[T]) -> None:
        self._items = items

    def map(self, fn: Callable[[T], U]) -> "Stream[U]":
        return Stream([fn(x) for x in self._items])

    def filter(self, pred: Callable[[T], bool]) -> "Stream[T]":
        return Stream([x for x in self._items if pred(x)])

    def __iter__(self) -> Iterator[T]:
        return iter(self._items)
END
    is(py($code), $code, 'Python: generic class with type vars');
}

# 15. property and classmethod
{
    my $code = <<'END';
class Temperature:
    def __init__(self, celsius: float) -> None:
        self._celsius = celsius

    \
    def celsius(self) -> float:
        return self._celsius

    @celsius.setter
    def celsius(self, value: float) -> None:
        if value < -273.15:
            raise ValueError("Below absolute zero")
        self._celsius = value

    \
    def fahrenheit(self) -> float:
        return self._celsius * 9 / 5 + 32

    @classmethod
    def from_fahrenheit(cls, f: float) -> "Temperature":
        return cls((f - 32) * 5 / 9)
END
    is(py($code), $code, 'Python: property and classmethod');
}

# 16. dunder methods
{
    my $code = <<'END';
class Vector:
    def __init__(self, x: float, y: float) -> None:
        self.x = x
        self.y = y

    def __add__(self, other: "Vector") -> "Vector":
        return Vector(self.x + other.x, self.y + other.y)

    def __mul__(self, scalar: float) -> "Vector":
        return Vector(self.x * scalar, self.y * scalar)

    def __abs__(self) -> float:
        return (self.x ** 2 + self.y ** 2) ** 0.5

    def __repr__(self) -> str:
        return f"Vector({self.x}, {self.y})"

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, Vector):
            return NotImplemented
        return self.x == other.x and self.y == other.y
END
    is(py($code), $code, 'Python: dunder methods');
}

# 17. pathlib
{
    my $code = <<'END';
from pathlib import Path

def find_files(directory: str, pattern: str) -> list[Path]:
    base = Path(directory)
    return sorted(base.rglob(pattern))

def read_text(path: str | Path, encoding: str = "utf-8") -> str:
    return Path(path).read_text(encoding=encoding)

def write_text(path: str | Path, text: str, encoding: str = "utf-8") -> None:
    p = Path(path)
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(text, encoding=encoding)
END
    is(py($code), $code, 'Python: pathlib operations');
}

# 18. match statement (3.10+)
{
    my $code = <<'END';
def handle_event(event: dict) -> str:
    match event:
        case {"type": "click", "x": x, "y": y}:
            return f"click at ({x}, {y})"
        case {"type": "keydown", "key": key} if key.startswith("Arrow"):
            return f"arrow key: {key}"
        case {"type": "keydown", "key": key}:
            return f"key: {key}"
        case {"type": t}:
            return f"unknown event: {t}"
        case _:
            return "invalid event"
END
    is(py($code), $code, 'Python: structural pattern matching');
}

# 19. slots
{
    my $code = <<'END';
class Point:
    __slots__ = ("x", "y")

    def __init__(self, x: float, y: float) -> None:
        self.x = x
        self.y = y

    def distance_to(self, other: "Point") -> float:
        return ((self.x - other.x) ** 2 + (self.y - other.y) ** 2) ** 0.5

    def __repr__(self) -> str:
        return f"Point({self.x}, {self.y})"
END
    is(py($code), $code, 'Python: __slots__');
}

# 20. nested functions / closures
{
    my $code = <<'END';
def make_adder(n: int):
    def adder(x: int) -> int:
        return x + n
    return adder

def compose(*fns):
    def composed(x):
        for fn in reversed(fns):
            x = fn(x)
        return x
    return composed

def memoize(fn):
    cache = {}
    def wrapper(*args):
        if args not in cache:
            cache[args] = fn(*args)
        return cache[args]
    return wrapper
END
    is(py($code), $code, 'Python: closures and higher-order functions');
}

# 21. enum
{
    my $code = <<'END';
from enum import Enum, auto

class Color(Enum):
    RED   = auto()
    GREEN = auto()
    BLUE  = auto()

class Status(Enum):
    PENDING   = "pending"
    ACTIVE    = "active"
    CANCELLED = "cancelled"
    DONE      = "done"

    def is_terminal(self) -> bool:
        return self in (Status.CANCELLED, Status.DONE)
END
    is(py($code), $code, 'Python: Enum classes');
}

# 22. abstract base class
{
    my $code = <<'END';
from abc import ABC, abstractmethod

class Storage(ABC):
    @abstractmethod
    def get(self, key: str) -> bytes | None: ...

    @abstractmethod
    def set(self, key: str, value: bytes) -> None: ...

    @abstractmethod
    def delete(self, key: str) -> bool: ...

    def get_str(self, key: str, encoding: str = "utf-8") -> str | None:
        data = self.get(key)
        return data.decode(encoding) if data is not None else None
END
    is(py($code), $code, 'Python: abstract base class');
}

# 23. itertools usage
{
    my $code = <<'END';
import itertools
from typing import Iterable

def chunk(iterable: Iterable, size: int):
    it = iter(iterable)
    while batch := list(itertools.islice(it, size)):
        yield batch

def sliding_window(iterable: Iterable, n: int):
    it = iter(iterable)
    window = []
    for item in it:
        window.append(item)
        if len(window) == n:
            yield tuple(window)
            window.pop(0)
END
    is(py($code), $code, 'Python: itertools and walrus operator');
}

# 24. Protocol
{
    my $code = <<'END';
from typing import Protocol, runtime_checkable

@runtime_checkable
class Comparable(Protocol):
    def __lt__(self, other) -> bool: ...
    def __le__(self, other) -> bool: ...

class Sortable(Protocol):
    def sort(self) -> None: ...

def minimum(items: list[Comparable]) -> Comparable:
    if not items:
        raise ValueError("empty sequence")
    result = items[0]
    for item in items[1:]:
        if item < result:
            result = item
    return result
END
    is(py($code), $code, 'Python: Protocol');
}

# 25. __init_subclass__
{
    my $code = <<'END';
class Plugin:
    _registry: dict[str, type] = {}

    def __init_subclass__(cls, name: str = "", **kwargs) -> None:
        super().__init_subclass__(**kwargs)
        if name:
            Plugin._registry[name] = cls

    @classmethod
    def get(cls, name: str) -> type | None:
        return cls._registry.get(name)

class JsonPlugin(Plugin, name="json"):
    pass

class CsvPlugin(Plugin, name="csv"):
    pass
END
    is(py($code), $code, 'Python: __init_subclass__ plugin registry');
}

# ── normalization tests ────────────────────────────────────────────

# 26
{
    my $in = <<'END';
def factorial(n: int) -> int:
if n <= 1:
return 1
return n * factorial(n - 1)
END
    my $exp = <<'END';
def factorial(n: int) -> int:
if n <= 1:
return 1
return n * factorial(n - 1)
END
    is(py($in), $exp, 'Python: unindented factorial normalised');
}

# 27
{
    my $in = <<'END';
def binary_search(arr: list, target) -> int:
lo, hi = 0, len(arr) - 1
while lo <= hi:
mid = (lo + hi) // 2
if arr[mid] == target:
return mid
elif arr[mid] < target:
lo = mid + 1
else:
hi = mid - 1
return -1
END
    my $exp = <<'END';
def binary_search(arr: list, target) -> int:
lo, hi = 0, len(arr) - 1
while lo <= hi:
mid = (lo + hi) // 2
if arr[mid] == target:
return mid
elif arr[mid] < target:
lo = mid + 1
else:
hi = mid - 1
return -1
END
    is(py($in), $exp, 'Python: unindented binary search normalised');
}

# 28
{
    my $in = <<'END';
class Stack:
def __init__(self):
self._items = []
def push(self, item):
self._items.append(item)
def pop(self):
if not self._items:
raise IndexError("pop from empty stack")
return self._items.pop()
def peek(self):
return self._items[-1] if self._items else None
def __len__(self):
return len(self._items)
END
    my $exp = <<'END';
class Stack:
def __init__(self):
self._items = []
def push(self, item):
self._items.append(item)
def pop(self):
if not self._items:
raise IndexError("pop from empty stack")
return self._items.pop()
def peek(self):
return self._items[-1] if self._items else None
def __len__(self):
return len(self._items)
END
    is(py($in), $exp, 'Python: unindented Stack class normalised');
}

# 29
{
    my $in = <<'END';
def merge_sort(arr: list) -> list:
if len(arr) <= 1:
return arr
mid = len(arr) // 2
left = merge_sort(arr[:mid])
right = merge_sort(arr[mid:])
result, i, j = [], 0, 0
while i < len(left) and j < len(right):
if left[i] <= right[j]:
result.append(left[i]); i += 1
else:
result.append(right[j]); j += 1
result.extend(left[i:])
result.extend(right[j:])
return result
END
    my $exp = <<'END';
def merge_sort(arr: list) -> list:
if len(arr) <= 1:
return arr
mid = len(arr) // 2
left = merge_sort(arr[:mid])
right = merge_sort(arr[mid:])
result, i, j = [], 0, 0
while i < len(left) and j < len(right):
if left[i] <= right[j]:
result.append(left[i]); i += 1
else:
result.append(right[j]); j += 1
result.extend(left[i:])
result.extend(right[j:])
return result
END
    is(py($in), $exp, 'Python: unindented merge sort normalised');
}

# 30
{
    my $in = <<'END';
def flatten(lst, depth=None):
for item in lst:
if isinstance(item, list) and (depth is None or depth > 0):
yield from flatten(item, None if depth is None else depth - 1)
else:
yield item
END
    my $exp = <<'END';
def flatten(lst, depth=None):
for item in lst:
if isinstance(item, list) and (depth is None or depth > 0):
yield from flatten(item, None if depth is None else depth - 1)
else:
yield item
END
    is(py($in), $exp, 'Python: unindented flatten generator normalised');
}

# ── idempotency tests ──────────────────────────────────────────────

for my $snippet (
    "class Descriptor:\n    def __set_name__(self,owner,name):\n        self.name=name\n    def __get__(self,obj,objtype=None):\n        if obj is None: return self\n        return obj.__dict__.get(self.name)\n    def __set__(self,obj,value):\n        obj.__dict__[self.name]=value\n",
    "from functools import lru_cache\n\(maxsize=None)\ndef fib(n:int)->int:\n    if n<2: return n\n    return fib(n-1)+fib(n-2)\n",
    "def retry(n:int,exc=Exception):\n    import functools,time\n    def decorator(fn):\n        \.wraps(fn)\n        def wrapper(*a,**k):\n            for i in range(n):\n                try: return fn(*a,**k)\n                except exc:\n                    if i==n-1: raise\n                    time.sleep(2**i)\n        return wrapper\n    return decorator\n",
    "class RingBuffer:\n    def __init__(self,cap):\n        self._buf=[None]*cap\n        self._read=self._write=self._size=0\n        self._cap=cap\n    def push(self,v):\n        if self._size==self._cap: raise OverflowError\n        self._buf[self._write]=v\n        self._write=(self._write+1)%self._cap\n        self._size+=1\n    def pop(self):\n        if not self._size: raise IndexError\n        v=self._buf[self._read]\n        self._read=(self._read+1)%self._cap\n        self._size-=1\n        return v\n",
    "from typing import TypeVar,Callable\nT=TypeVar('T')\ndef pipe(*fns:Callable)->Callable:\n    def apply(x):\n        for fn in fns:\n            x=fn(x)\n        return x\n    return apply\n",
    "class Multiton:\n    _instances={}\n    def __new__(cls,key):\n        if key not in cls._instances:\n            inst=super().__new__(cls)\n            inst._key=key\n            cls._instances[key]=inst\n        return cls._instances[key]\n",
    "def topological_sort(graph:dict)->list:\n    visited,order=set(),[]\n    def dfs(node):\n        visited.add(node)\n        for dep in graph.get(node,[]):\n            if dep not in visited: dfs(dep)\n        order.append(node)\n    for node in graph:\n        if node not in visited: dfs(node)\n    return order[::-1]\n",
    "class Observable:\n    def __init__(self): self._subs=[]\n    def subscribe(self,fn): self._subs.append(fn); return lambda:self._subs.remove(fn)\n    def emit(self,v): [f(v) for f in list(self._subs)]\n    def map(self,fn):\n        out=Observable()\n        self.subscribe(lambda v:out.emit(fn(v)))\n        return out\n    def filter(self,pred):\n        out=Observable()\n        self.subscribe(lambda v:pred(v) and out.emit(v))\n        return out\n",
    "import threading\nclass ThreadSafeCounter:\n    def __init__(self,n=0):\n        self._n=n\n        self._lock=threading.Lock()\n    def increment(self):\n        with self._lock: self._n+=1\n    def decrement(self):\n        with self._lock: self._n-=1\n    \\n    def value(self):\n        with self._lock: return self._n\n",
    "def chunk(lst,size):\n    return [lst[i:i+size] for i in range(0,len(lst),size)]\ndef flatten(lst):\n    return [x for sublist in lst for x in sublist]\ndef zip_with(fn,a,b):\n    return [fn(x,y) for x,y in zip(a,b)]\n",
) {
    my $once = py($snippet);
    is(py($once), $once, 'Python: snippet idempotent');
}

done_testing;
